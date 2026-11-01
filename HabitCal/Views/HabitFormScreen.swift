import HabitCalKit
import SwiftUI

/// Add or edit a habit (T-003 §5, B.8–B.17). Replaces the list inside the popover. Edits save as
/// they're made; a new habit waits for Add (T-038).
struct HabitFormScreen: View {
    @Environment(AppModel.self) private var model
    @FocusState private var nameFocused: Bool
    /// The fields' own text. A clamped value pushed back through a model binding doesn't reach a
    /// field while it's being typed in, so the limit is applied here, where the field sees it (E.4).
    @State private var name = ""
    @State private var note = ""

    var body: some View {
        if let form = model.form {
            VStack(alignment: .leading, spacing: 10) {
                header(form)
                label("Name")
                TextField("e.g. Push-ups", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .focused($nameFocused)
                    .onSubmit { model.saveForm() }
                    .accessibilityIdentifier("nameField")
                    .accessibilityLabel("Name")
                label("Repeats on")
                dayButtons(form.draft.days)
                label("Notes")
                notes
                hints(form)
                if case .edit = form.mode {
                    Divider()
                    deleteSection(form)
                }
            }
            .padding(.horizontal, PopoverRoot.margin)
            .padding(.vertical, 12)
            .onChange(of: name) { _, value in
                if value.count > HabitDraft.maxNameLength { name = String(value.prefix(HabitDraft.maxNameLength)) }
                model.updateDraft { $0.name = name }
            }
            .onChange(of: note) { _, value in
                if value.count > HabitDraft.maxNoteLength { note = String(value.prefix(HabitDraft.maxNoteLength)) }
                model.updateDraft { $0.note = note }
            }
            .onAppear {
                name = form.draft.name
                note = form.draft.note
                // Focus after the form is in the window; set synchronously, it's lost.
                DispatchQueue.main.async { nameFocused = true }
            }
        }
    }

    private func header(_ form: HabitForm) -> some View {
        let adding = form.mode == .add
        return ZStack {
            Text(adding ? "New habit" : "Edit habit").font(.headline)
            HStack {
                // The window handles this shortcut before a focused field sees Esc (T-003 B.12).
                Button("Close") { model.closeForm() }
                    .buttonStyle(.hover(outset: 3))
                    .keyboardShortcut(.cancelAction)
                Spacer()
                // Edits save as they're made; only a new habit waits for Add (T-038).
                if adding {
                    Button("Add") { model.saveForm() }
                        .buttonStyle(.hover(outset: 3))
                        .fontWeight(.semibold)
                        .disabled(!form.draft.isValid)
                }
            }
        }
    }

    private func label(_ text: String) -> some View {
        Text(text).font(.caption.weight(.semibold)).foregroundStyle(.secondary)
    }

    private func dayButtons(_ selected: Set<Int>) -> some View {
        HStack(spacing: 4) {
            ForEach(model.weekStart.orderedWeekdays, id: \.self) { weekday in
                let on = selected.contains(weekday)
                Button {
                    model.updateDraft { draft in
                        if on { draft.days.remove(weekday) } else { draft.days.insert(weekday) }
                    }
                } label: {
                    Text(MonthNames.weekdayInitial(weekday))
                        .font(.callout.weight(.semibold))
                        .frame(width: 26, height: 26)
                        .foregroundStyle(on ? Color.white : Color.primary)
                        .background(on ? Color.accentColor : Color.secondary.opacity(0.15), in: Circle())
                        .contentShape(Circle())
                }
                .buttonStyle(.hover(cornerRadius: 13, overLabel: true))
                .frame(maxWidth: .infinity)
                .help(MonthNames.weekdayName(weekday))
                .accessibilityLabel(MonthNames.weekdayName(weekday))
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
    }

    private var notes: some View {
        TextEditor(text: $note)
            .font(.callout)
            .scrollContentBackground(.hidden)
            .padding(4)
            .frame(height: 54)
            .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 6))
            .overlay(alignment: .topLeading) {
                if note.isEmpty {
                    Text("Optional details, e.g. 3 sets of 20, or the route you run")
                        .font(.callout)
                        .foregroundStyle(.tertiary)
                        .padding(.horizontal, 9)
                        .padding(.vertical, 4)
                        .allowsHitTesting(false)
                }
            }
            .accessibilityIdentifier("notesField")
            .accessibilityLabel("Notes")
    }

    @ViewBuilder
    private func hints(_ form: HabitForm) -> some View {
        if form.draft.days.isEmpty {
            hint("Pick at least one day.")
        } else if model.formChangesSchedule {
            hint("The new schedule starts today. Past days, and your streak, keep the old one.")
        }
    }

    private func hint(_ text: String) -> some View {
        Text(text).font(.caption).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
    }

    @ViewBuilder
    private func deleteSection(_ form: HabitForm) -> some View {
        if form.confirmingDelete, case .edit(let id) = form.mode, let habit = model.habits[id] {
            VStack(alignment: .leading, spacing: 6) {
                Text("Delete “\(habit.name)”?")
                    .fontWeight(.semibold)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Its history and streaks are deleted too. This can't be undone.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                HStack {
                    Spacer()
                    Button("Cancel") { model.setConfirmingDelete(false) }
                        .accessibilityIdentifier("confirmCancel")
                    Button("Delete", role: .destructive) { model.deleteFromForm() }
                        .tint(.red)
                }
            }
        } else {
            Button {
                model.setConfirmingDelete(true)
            } label: {
                HStack(spacing: 6) {
                    PhosphorIcon("trash", size: 14)
                    Text("Delete habit")
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .foregroundStyle(.red)
                .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 7))
            }
            .buttonStyle(.hover(cornerRadius: 7, overLabel: true))
            .accessibilityLabel("Delete habit")
        }
    }
}
