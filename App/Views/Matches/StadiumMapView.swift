import SwiftUI
import UltrasEuropaCore

/// A schematic top-down view of the stadium — four stands around a pitch,
/// each tappable to apply for that section. Sections are far from equally
/// contested (the Ultras Section hardest of all), so each shows its
/// current chance of success before the player commits to it. A section
/// already applied for this match shows its locked-in result instead and
/// can't be tapped again — see `CharacterStore.requestHomeSeat`.
struct StadiumMapView: View {
    let triedSeats: [SeatCategory: Bool]
    let chance: (SeatCategory) -> Double
    let isGuaranteed: (SeatCategory) -> Bool
    let onSelect: (SeatCategory) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text("Tap a section to apply for tickets there. Some sections are far more contested than others.")
                    .font(.caption)
                    .foregroundStyle(Theme.secondaryText)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                ZStack {
                    stand(.ultrasSection, alignment: .top)
                    stand(.mainStand, alignment: .leading)
                    stand(.familySection, alignment: .trailing)
                    stand(.behindTheGoal, alignment: .bottom)

                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(red: 0.09, green: 0.35, blue: 0.14))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.35), lineWidth: 1.5))
                        .frame(width: 120, height: 190)
                }
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .padding()
            }
            .padding(.top)
            .background(Theme.background)
            .navigationTitle("Stadium Map")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }

    @ViewBuilder
    private func stand(_ seat: SeatCategory, alignment: Alignment) -> some View {
        let outcome = triedSeats[seat]
        let guaranteed = isGuaranteed(seat)

        VStack(spacing: 4) {
            Text(seat.displayName).font(.caption.bold()).multilineTextAlignment(.center)
            if let outcome {
                Text(outcome ? "Granted" : "Denied").font(.caption2).bold()
            } else if guaranteed {
                Text("Guaranteed").font(.caption2).foregroundStyle(Theme.secondaryText)
            } else {
                Text("\(Int((chance(seat) * 100).rounded()))% chance").font(.caption2).foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(10)
        .frame(minWidth: 100)
        .background(
            seat == .ultrasSection ? Theme.accent : Theme.cardBackground,
            in: RoundedRectangle(cornerRadius: 10)
        )
        .foregroundStyle(seat == .ultrasSection ? Theme.accentForeground : Theme.primaryText)
        .opacity(outcome != nil ? 0.55 : 1)
        .contentShape(Rectangle())
        .onTapGesture {
            guard outcome == nil else { return }
            onSelect(seat)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
    }
}

#Preview {
    StadiumMapView(
        triedSeats: [.mainStand: false],
        chance: { seat in HomeSeatRequestEngine.chance(for: seat, prestigeTier: 3, hasUltrasSeasonTicket: false) },
        isGuaranteed: { _ in false },
        onSelect: { _ in }
    )
}
