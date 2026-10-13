import SwiftUI

// List of all presets
struct PresetsView: View {
    @Bindable var store: TasbihStore
    @Environment(\.dismiss) private var dismiss
    @State private var path: [UUID] = []
    @State private var confirmRestore = false

    var body: some View {
        NavigationStack(path: $path) {
            List {
                Section {
                    ForEach($store.presets) { $preset in
                        NavigationLink(value: preset.id) {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(preset.name).font(.headline)
                                Text(preset.isFreeCount
                                     ? "Unlimited"
                                     : "\(preset.rounds.count) rounds · \(preset.total) total")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .deleteDisabled(store.presets.count == 1)
                    }
                    .onDelete { store.presets.remove(atOffsets: $0) }
                    .onMove { store.presets.move(fromOffsets: $0, toOffset: $1) }
                }

                Section {
                    Button("Restore default presets", role: .destructive) {
                        confirmRestore = true
                    }
                }
            }
            .navigationTitle("Presets")
            .navigationDestination(for: UUID.self) { id in
                if let i = store.presets.firstIndex(where: { $0.id == id }) {
                    PresetEditView(preset: $store.presets[i])
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                }
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        let new = Preset(name: "New preset", rounds: [Round(target: 33)])
                        store.presets.append(new)
                        path.append(new.id)
                    } label: {
                        Label("New preset", systemImage: "plus")
                    }
                }
            }
            .confirmationDialog("Restore default presets?",
                                isPresented: $confirmRestore,
                                titleVisibility: .visible) {
                Button("Restore", role: .destructive) { store.restoreDefaults() }
            } message: {
                Text("Your custom presets and label changes will be replaced.")
            }
        }
        .onChange(of: store.presets) { store.presetsChanged() }
    }
}

// Editing one preset
struct PresetEditView: View {
    @Binding var preset: Preset

    var body: some View {
        Form {
            Section("Name") {
                TextField("Preset name", text: $preset.name)
            }

            Section {
                ForEach($preset.rounds) { $round in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Round \(roundNumber(round))")
                                .font(.subheadline.bold())
                            Spacer()
                            TextField("33", value: $round.target, format: .number)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.trailing)
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                            Stepper("Count", value: $round.target, in: 1...10000)
                                .labelsHidden()
                        }
                        TextField("Label (optional), e.g. سبحان الله",
                                  text: $round.label, axis: .vertical)
                    }
                    .padding(.vertical, 4)
                    .onChange(of: round.target) {
                        if round.target < 1 { round.target = 1 }
                    }
                }
                .onDelete { preset.rounds.remove(atOffsets: $0) }
                .onMove { preset.rounds.move(fromOffsets: $0, toOffset: $1) }

                Button {
                    preset.rounds.append(Round(target: preset.rounds.last?.target ?? 33))
                } label: {
                    Label("Add round", systemImage: "plus.circle.fill")
                }
            } header: {
                Text("Rounds")
            } footer: {
                Text(preset.isFreeCount
                     ? "No rounds = free count with no limit."
                     : "Total: \(preset.total)")
            }
        }
        .navigationTitle(preset.name.isEmpty ? "Preset" : preset.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { EditButton() }
    }

    private func roundNumber(_ round: Round) -> Int {
        (preset.rounds.firstIndex(where: { $0.id == round.id }) ?? 0) + 1
    }
}
