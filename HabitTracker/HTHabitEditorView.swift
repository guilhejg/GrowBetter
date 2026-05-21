import SwiftUI
import SwiftData
import UIKit

struct HTHabitEditorView: View {
    enum Mode {
        case create
        case edit(HTHabit)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let mode: Mode

    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var iconName: String = "figure.walk"
    @State private var colorHex: String = "#34C759"

    @State private var themeIsDark: Bool = true
    @State private var squareFormat: Bool = true
    @State private var showCompletionIndicator: Bool = true
    @State private var showDescription: Bool = true
    @State private var showStreak: Bool = false

    @State private var editingTitle = false
    @State private var editingSubtitle = false

    @Query private var logs: [HTHabitLog]

    @State private var shareImage: UIImage?
    @State private var showingShare = false

    private var editingHabit: HTHabit? {
        if case .edit(let h) = mode { return h }
        return nil
    }

    init(mode: Mode) {
        self.mode = mode

        if case .edit(let h) = mode {
            let hid = h.persistentModelID
            _logs = Query(filter: #Predicate<HTHabitLog> { log in
                log.habit.persistentModelID == hid
            })
        } else {
            _logs = Query(filter: #Predicate<HTHabitLog> { _ in false })
        }
    }

    private var accent: Color { Color(hex: colorHex) }

    private var completedDays: Set<Date> {
        Set(logs.map { Calendar.current.startOfDay(for: $0.date) })
    }

    var body: some View {
        GeometryReader { rootGeo in
            let safeTop = rootGeo.safeAreaInsets.top
            let isEditingText = editingTitle || editingSubtitle

            // ✅ congela a altura base (não muda com teclado)
            let baseHeight = rootGeo.size.height
            let previewMaxHeight = min(baseHeight * 0.44, 520)

            ZStack {
                Color.black.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 18) {
                        VStack(spacing: 0) {

                            // ✅ faixa preta que impede o preview de invadir a topbar
                            Color.black
                                .frame(height: safeTop + HTConstants.topBarHeight)

                            previewResponsive(maxHeight: previewMaxHeight, safeTop: safeTop)
                        }
                        .padding(.top, 12)

                        stylePanel
                        optionsPanel

                        if editingHabit != nil {
                            deleteButton
                        }

                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24 + HTConstants.topBarHeight)
                }

                // ✅ topbar fixo, não depende de safeAreaInset
                topBar
                    .ignoresSafeArea(.keyboard, edges: .bottom)
                    .frame(height: HTConstants.topBarHeight)
                    .padding(.top, safeTop)
                    .background(Color.clear)
                    .frame(maxHeight: .infinity, alignment: .top)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { loadIfNeeded() }
            .sheet(isPresented: $showingShare) {
                if let img = shareImage {
                    ShareSheet(activityItems: [img])
                }
            }
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack(spacing: 12) {
            Button { dismiss() } label: { topCircleIcon("xmark") }
                .buttonStyle(.plain)

            Spacer()

            Text("Habit Editor")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)

            Spacer()

            HStack(spacing: 10) {
                Button { Task { @MainActor in share() } } label: { topCircleIcon("square.and.arrow.up") }
                    .buttonStyle(.plain)

                Button { save() } label: { topCircleIcon("checkmark") }
                    .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 16)
    }

    private func topCircleIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: HTConstants.topIconSize, height: HTConstants.topIconSize)
            .background(Circle().fill(Color.white.opacity(0.10)))
            .clipShape(Circle())
            .contentShape(Circle())
    }

    // MARK: - Preview responsivo

    private func previewResponsive(maxHeight: CGFloat, safeTop: CGFloat) -> some View {
        GeometryReader { geo in
            let scale = UIScreen.main.scale
            let snappedW = floor(geo.size.width * scale) / scale
            let ratio: CGFloat = squareFormat ? 1.0 : (16.0 / 9.0)

            PreviewCanvas(
                title: $name,
                subtitle: $detail,
                iconName: iconName,
                accent: accent,
                completedDays: completedDays,
                weeks: HTConstants.heatmapWeeks,
                showCompletionIndicator: showCompletionIndicator,
                showDescription: showDescription,
                allowInlineEdit: true,
                editingTitle: $editingTitle,
                editingSubtitle: $editingSubtitle,
                contentTopInset: 10,
                isDark: themeIsDark
            )
            .frame(width: snappedW)
            .aspectRatio(ratio, contentMode: .fit)
            .frame(maxHeight: maxHeight)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .frame(height: maxHeight)
    }

    // MARK: - STYLE

    private var stylePanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STYLE")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))

            VStack(spacing: 14) {
                iconPicker
                colorPicker
            }
            .padding(14)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var iconPicker: some View {
        let icons = [
            "figure.walk", "fork.knife", "dumbbell", "book", "drop",
            "bed.double", "leaf", "timer", "music.note", "brain.head.profile"
        ]

        return VStack(alignment: .leading, spacing: 10) {
            Text("Icon")
                .foregroundStyle(.white.opacity(0.9))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 10) {
                ForEach(icons, id: \.self) { icon in
                    Button { iconName = icon } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(icon == iconName ? 0.18 : 0.08))
                            Image(systemName: icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(icon == iconName ? 1.0 : 0.75))
                        }
                        .frame(height: 42)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var colorPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Color")
                .foregroundStyle(.white.opacity(0.9))

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 7), spacing: 12) {
                ForEach(HTEditorPalette.hexes, id: \.self) { hex in
                    Button { colorHex = hex } label: {
                        ZStack {
                            Circle()
                                .fill(Color(hex: hex))
                                .frame(width: 26, height: 26)

                            if hex.lowercased() == colorHex.lowercased() {
                                Circle()
                                    .stroke(Color.black.opacity(0.75), lineWidth: 3)
                                    .frame(width: 32, height: 32)
                            }
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    // MARK: - OPTIONS

    private var optionsPanel: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OPTIONS")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.white.opacity(0.55))

            VStack(spacing: 0) {
                rowTheme
                divider
                rowToggle(title: "Show Completion Indicator", isOn: $showCompletionIndicator)
                divider
                rowToggle(title: "Show Description", isOn: $showDescription)
                divider
                rowToggle(title: "Show Streak", isOn: $showStreak)
            }
            .padding(14)
            .background(Color.white.opacity(0.10))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            )
        }
    }

    private var rowTheme: some View {
        HStack {
            Text("Theme")
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Picker("", selection: $themeIsDark) {
                Text("Light").tag(false)
                Text("Dark").tag(true)
            }
            .pickerStyle(.segmented)
            .frame(width: 170)
        }
        .padding(.vertical, 10)
    }

    private func rowToggle(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .foregroundStyle(.white.opacity(0.9))
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.vertical, 10)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.vertical, 2)
    }

    // MARK: - Delete

    private var deleteButton: some View {
        Button(role: .destructive) { deleteHabit() } label: {
            Text("Excluir hábito")
                .font(.system(size: 16, weight: .semibold))
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.red.opacity(0.18))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(Color.red.opacity(0.35), lineWidth: 1)
                )
        }
    }

    // MARK: - Data

    private func loadIfNeeded() {
        guard let h = editingHabit else { return }
        name = h.name
        detail = h.detailText
        iconName = h.iconName
        colorHex = h.colorHex
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        if let h = editingHabit {
            h.name = trimmed
            h.detailText = detail.trimmingCharacters(in: .whitespacesAndNewlines)
            h.iconName = iconName
            h.colorHex = colorHex
        } else {
            context.insert(
                HTHabit(
                    name: trimmed,
                    detailText: detail.trimmingCharacters(in: .whitespacesAndNewlines),
                    iconName: iconName,
                    colorHex: colorHex
                )
            )
        }

        try? context.save()
        dismiss()
    }

    private func deleteHabit() {
        guard let h = editingHabit else { return }
        context.delete(h)
        try? context.save()
        dismiss()
    }

    // MARK: - Share (ImageRenderer + fallback)

    @MainActor
    private func share() {
        let exportSize: CGSize = squareFormat
            ? CGSize(width: 1024, height: 1024)
            : CGSize(width: 1200, height: 675)

        let exportView = PreviewCanvasExport(
            title: name.isEmpty ? "Seu hábito" : name,
            subtitle: detail.isEmpty ? "Descrição do hábito" : detail,
            iconName: iconName,
            accent: accent,
            completedDays: completedDays,
            weeks: HTConstants.heatmapWeeks,     // ✅ mesmo da Home
            showCompletionIndicator: showCompletionIndicator,
            showDescription: showDescription,
            isDark: themeIsDark
        )
        .frame(width: exportSize.width, height: exportSize.height)

        let renderer = ImageRenderer(content: exportView)
        renderer.scale = UIScreen.main.scale
        renderer.proposedSize = .init(exportSize)

        if let img = renderer.uiImage {
            shareImage = img
            showingShare = true
            return
        }

        if let img2 = snapshot(of: exportView, size: exportSize) {
            shareImage = img2
            showingShare = true
        }
    }
}

// MARK: - Snapshot fallback (UIKit)

@MainActor
private func snapshot<V: View>(of view: V, size: CGSize) -> UIImage? {
    let controller = UIHostingController(rootView: view)
    controller.view.bounds = CGRect(origin: .zero, size: size)
    controller.view.backgroundColor = .clear

    let renderer = UIGraphicsImageRenderer(size: size)
    return renderer.image { _ in
        controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
    }
}

// MARK: - Preview Canvas (inline edit)

private struct PreviewCanvas: View {
    @Binding var title: String
    @Binding var subtitle: String

    let iconName: String
    let accent: Color
    let completedDays: Set<Date>
    let weeks: Int
    let showCompletionIndicator: Bool
    let showDescription: Bool

    let allowInlineEdit: Bool
    @Binding var editingTitle: Bool
    @Binding var editingSubtitle: Bool
    let contentTopInset: CGFloat
    let isDark: Bool

    private enum Field: Hashable { case title, subtitle }
    @FocusState private var focused: Field?

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            RoundedRectangle(cornerRadius: 0, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [accent.opacity(0.95), accent.opacity(0.55)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack {
                Spacer(minLength: 0)
                card.padding(.horizontal, 18)
                Spacer(minLength: 0)
            }
            .padding(.top, contentTopInset)
            .padding(.bottom, 14)

        }
        .clipped()
        .onTapGesture {
            editingTitle = false
            editingSubtitle = false
            focused = nil
        }
    }

    private var card: some View {
        VStack(spacing: 10) {
            HStack(spacing: 12) {
                iconBox

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        if allowInlineEdit && editingTitle {
                            TextField("Seu hábito", text: $title)
                                .focused($focused, equals: .title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .autocorrectionDisabled()
                                .submitLabel(.done)
                                .onSubmit { editingTitle = false; focused = nil }
                                .onAppear { focused = .title }
                        } else {
                            Text(title.isEmpty ? "Seu hábito" : title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)
                        }

                        if allowInlineEdit {
                            Button {
                                editingTitle.toggle()
                                editingSubtitle = false
                                focused = editingTitle ? .title : nil
                            } label: {
                                Image(systemName: "pencil")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.75))
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    if showDescription {
                        HStack(spacing: 8) {
                            if allowInlineEdit && editingSubtitle {
                                TextField("Descrição do hábito", text: $subtitle)
                                    .focused($focused, equals: .subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.75))
                                    .autocorrectionDisabled()
                                    .submitLabel(.done)
                                    .onSubmit { editingSubtitle = false; focused = nil }
                                    .onAppear { focused = .subtitle }
                            } else {
                                Text(subtitle.isEmpty ? "Descrição do hábito" : subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.70))
                                    .lineLimit(1)
                            }

                            if allowInlineEdit {
                                Button {
                                    editingSubtitle.toggle()
                                    editingTitle = false
                                    focused = editingSubtitle ? .subtitle : nil
                                } label: {
                                    Image(systemName: "pencil")
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.65))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }

                Spacer()

                if showCompletionIndicator {
                    completionBox
                }
            }

            HTHeatmapView(
                color: accent,
                completedDays: completedDays,
                weeks: weeks,
                mostRecentFirst: true
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(isDark ? Color.black.opacity(0.28) : Color.white.opacity(0.22))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Color.white.opacity(isDark ? 0.10 : 0.14), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
    }

    private var iconBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.white.opacity(0.10))
            Image(systemName: iconName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white.opacity(0.95))
        }
        .frame(width: 44, height: 44)
    }

    private var completionBox: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(accent)
            Image(systemName: "checkmark")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.black.opacity(0.85))
        }
        .frame(width: 44, height: 44)
    }
}

// MARK: - Export canvas (sem lápis)

private struct PreviewCanvasExport: View {
    let title: String
    let subtitle: String
    let iconName: String
    let accent: Color
    let completedDays: Set<Date>
    let weeks: Int
    let showCompletionIndicator: Bool
    let showDescription: Bool
    let isDark: Bool

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Rectangle().fill(accent)

            VStack {
                Spacer(minLength: 0)

                VStack(spacing: 10) {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(Color.white.opacity(0.10))
                            Image(systemName: iconName)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundStyle(.white.opacity(0.95))
                        }
                        .frame(width: 44, height: 44)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 17, weight: .semibold))
                                .foregroundStyle(.white)
                                .lineLimit(1)

                            if showDescription {
                                Text(subtitle)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.70))
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if showCompletionIndicator {
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(accent)
                                Image(systemName: "checkmark")
                                    .font(.system(size: 18, weight: .bold))
                                    .foregroundStyle(.black.opacity(0.85))
                            }
                            .frame(width: 44, height: 44)
                        }
                    }

                    HTHeatmapView(
                        color: accent,
                        completedDays: completedDays,
                        weeks: weeks,
                        mostRecentFirst: true
                    )
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(isDark ? Color.black.opacity(0.28) : Color.white.opacity(0.22))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(isDark ? 0.10 : 0.14), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.35), radius: 18, x: 0, y: 10)
                .padding(.horizontal, 18)

                Spacer(minLength: 0)
            }
            .padding(.vertical, 14)

        }
        .clipped()
    }
}

// BADGE

// MARK: - Share Sheet

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}

// MARK: - Palette

private enum HTEditorPalette {
    static let hexes: [String] = [
        "#FF5A5F", "#FF9F0A", "#FFD60A", "#FFCC00", "#B7F000", "#34C759", "#2ECC71",
        "#00D7FF", "#0A84FF", "#5E5CE6", "#8E5CF6", "#BF5AF2", "#FF3BFA", "#FF66C4",
        "#FF2D55", "#A0A0A0", "#7D7D7D", "#C7C7C7", "#8E8E93", "#D1D1D6", "#AEAEB2"
    ]
}
