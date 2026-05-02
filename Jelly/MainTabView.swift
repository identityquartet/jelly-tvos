import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Home", systemImage: "house.fill") }
            MoviesView()
                .tabItem { Label("Movies", systemImage: "film.fill") }
            TVShowsView()
                .tabItem { Label("TV Shows", systemImage: "tv.fill") }
            SettingsView()
                .tabItem { Label("Settings", systemImage: "gear") }
        }
    }
}
