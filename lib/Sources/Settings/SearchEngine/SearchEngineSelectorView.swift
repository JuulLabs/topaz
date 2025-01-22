import SwiftUI

struct SearchEngineSelectorView: View {
    let model: SearchEngineSelectorModel

    var body: some View {
        Group {
            LabeledContent("Default search page") {
                Image(systemName: "chevron.down")
                    .rotationEffect(Angle(degrees: model.isExpanded ? 180 : 0))
            }
            .listRowTintedButton(color: Color.topaz800) {
                model.headerButtonTapped()
            }
            .listRowSeparator(model.isExpanded ? .hidden : .visible)
            if model.isExpanded {
                ForEach(model.rows, id: \.id) { row in
                    LabeledContent(row.displayName) {
                        Image(systemName: model.selectedRowId == row.id ? "checkmark.circle.fill" : "circle")
                            .animation(.interactiveSpring, value: model.selectedRowId)
                    }
                    .listRowTintedButton(color: Color.topaz800) {
                        model.rowButtonTapped(row.id)
                    }
                    .listRowSeparator(model.rows.last?.id == row.id ? .visible : .hidden)
                }
            }
        }
    }
}
