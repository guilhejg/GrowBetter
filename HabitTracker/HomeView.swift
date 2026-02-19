import SwiftUI
import SwiftData

struct HomeView: View {
    
    @Binding var selectedTab: HTTab
    
    @Query(sort: \HTHabit.createdAt, order: .forward)
    private var habits: [HTHabit]
    
    @State private var showingCreate = false
    @State private var selectedHabit: HTHabit?
    
    var body: some View {
        GeometryReader { geo in
            let safeTop = geo.safeAreaInsets.top
            let topTotal = HTConstants.topBarHeight + safeTop
            
            ZStack(alignment: .top) {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 14) {
                        
                        // Espaço reservado para a topbar
                        Color.clear
                            .frame(height: topTotal + 10)
                        
                        if habits.isEmpty {
                            VStack(spacing: 10) {
                                Text("Nenhum hábito ainda")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundStyle(.white.opacity(0.9))
                                
                                Text("Toque no + para criar o primeiro")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.white.opacity(0.65))
                            }
                            .padding(.top, 30)
                        } else {
                            ForEach(habits, id: \.persistentModelID) { habit in
                                HabitRowContainer(habit: habit)
                                    .onTapGesture {
                                        selectedHabit = habit
                                    }
                            }
                        }
                        
                        Spacer(minLength: 24)
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 24)
                }
                
                topBar(safeTop: safeTop)
                    .frame(height: topTotal)
                    .frame(maxWidth: .infinity)
                    .background(Color.black)
                    .ignoresSafeArea(edges: .top)
            }
        }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingCreate) {
            HTHabitEditorView(mode: .create)
        }
        .sheet(
            isPresented: Binding(
                get: { selectedHabit != nil },
                set: { if !$0 { selectedHabit = nil } }
            )
        ) {
            if let h = selectedHabit {
                HTHabitEditorView(mode: .edit(h))
            }
        }
    }
    
    // MARK: - Top Bar
    
    private func topBar(safeTop: CGFloat) -> some View {
        HStack(spacing: 12) {
            
            Button {
                // Configurações futuramente
            } label: {
                topCircleIcon("gearshape")
            }
            .buttonStyle(.plain)
            
            Text("HabitTracker")
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
            
            Spacer()
            
            HStack(spacing: 12) {
                
                // 🔥 Vai para a aba Stats
                Button {
                    selectedTab = .stats
                } label: {
                    Image(systemName: "chart.bar")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
                
                // ➕ Criar hábito
                Button {
                    showingCreate = true
                } label: {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 14)
            .frame(height: HTConstants.capsuleHeight)
            .background(Capsule().fill(Color.white.opacity(0.10)))
            .clipShape(Capsule())
            .contentShape(Capsule())
        }
        .padding(.horizontal, 16)
        .padding(.top, safeTop)
        .frame(height: HTConstants.topBarHeight + safeTop, alignment: .bottom)
    }
    
    private func topCircleIcon(_ systemName: String) -> some View {
        Image(systemName: systemName)
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(width: HTConstants.topIconSize,
                   height: HTConstants.topIconSize)
            .background(Circle().fill(Color.white.opacity(0.10)))
            .clipShape(Circle())
            .contentShape(Circle())
    }
}


// MARK: - Habit Row Container

private struct HabitRowContainer: View {
    
    let habit: HTHabit
    
    @Query private var logs: [HTHabitLog]
    
    init(habit: HTHabit) {
        self.habit = habit
        
        let hid = habit.persistentModelID
        
        _logs = Query(filter: #Predicate<HTHabitLog> { log in
            log.habit.persistentModelID == hid
        })
    }
    
    var body: some View {
        HabitRowView(
            habit: habit,
            logs: logs
        )
    }
}
