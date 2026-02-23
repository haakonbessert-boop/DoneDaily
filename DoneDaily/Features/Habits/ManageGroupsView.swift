import SwiftData
import SwiftUI

struct ManageGroupsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HabitGroup.sortOrder) private var groups: [HabitGroup]

    @State private var name = ""

    var body: some View {
        NavigationStack {
            List {
                Section("Neue Gruppe") {
                    HStack {
                        TextField("Gruppenname", text: $name)
                        Button("Hinzufügen") {
                            addGroup()
                        }
                        .disabled(trimmedName.isEmpty)
                    }
                }

                Section("Gruppen") {
                    if groups.isEmpty {
                        Text("Noch keine Gruppen vorhanden.")
                            .foregroundStyle(.secondary)
                    } else {
                        ForEach(groups) { group in
                            Text(group.name)
                        }
                        .onMove(perform: moveGroups)
                        .onDelete(perform: deleteGroups)
                    }
                }
            }
            .navigationTitle("Gruppen verwalten")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    EditButton()
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fertig") { dismiss() }
                }
            }
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func addGroup() {
        guard !trimmedName.isEmpty else { return }
        let exists = groups.contains { $0.name.caseInsensitiveCompare(trimmedName) == .orderedSame }
        guard !exists else { return }

        modelContext.insert(HabitGroup(name: trimmedName, sortOrder: groups.count))
        _ = modelContext.saveIfNeeded()
        name = ""
    }

    private func deleteGroups(at offsets: IndexSet) {
        for index in offsets {
            let group = groups[index]
            modelContext.delete(group)
        }
        normalizeSortOrder()
    }

    private func moveGroups(from source: IndexSet, to destination: Int) {
        var reordered = groups
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, group) in reordered.enumerated() {
            group.sortOrder = index
        }
        _ = modelContext.saveIfNeeded()
    }

    private func normalizeSortOrder() {
        let sorted = groups.sorted { $0.sortOrder < $1.sortOrder }
        for (index, group) in sorted.enumerated() {
            group.sortOrder = index
        }
        _ = modelContext.saveIfNeeded()
    }
}

#Preview {
    ManageGroupsView()
        .modelContainer(PreviewData.container)
}
