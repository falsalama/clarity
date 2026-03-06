import SwiftUI

struct ExploreView: View {
    var body: some View {
        List {
            Section {
                NavigationLink {
                    GuidanceHubView()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Guidance")
                        Text("Overview of teachers, sessions, and future offerings")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }

               
            } header: {
                Text("Guidance")
            } footer: {
                Text("Connect with teachers, practitioners, and future one-to-one offerings. Some options may also help support monasteries, nunneries, and universities.")
            }

            Section("Focus") {
                NavigationLink {
                    FocusSoundsHubView()
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Focus")
                        Text("Meditative sounds")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Section("Coming Soon") {
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Teachings",
                        subtitle: "Curated teachings and structured learning will appear here."
                    )
                } label: {
                    Label("Teachings", systemImage: "book.pages")
                }
                
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Podcast",
                        subtitle: "Talks, conversations, and reflective audio will appear here."
                    )
                } label: {
                    Label("Podcast", systemImage: "mic.circle")
                }
                
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Videos",
                        subtitle: "Selected video teachings and visual guidance will appear here."
                    )
                } label: {
                    Label("Videos", systemImage: "play.rectangle")
                }
                
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Courses",
                        subtitle: "Longer guided pathways and future modules will appear here."
                    )
                } label: {
                    Label("Courses", systemImage: "square.stack.3d.up")
                }
                
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Shop",
                        subtitle: "Future books, practice items, and selected merchandise may appear here."
                    )
                } label: {
                    Label("Shop", systemImage: "bag")
                }
            
                NavigationLink {
                    ExplorePlaceholderView(
                        title: "Make an Offering",
                        subtitle: "A future space for supporting monasteries, nunneries, universities, and authentic practice communities."
                    )
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 8) {
                            Image(systemName: "seal.fill")
                                .foregroundStyle(.secondary)

                            Text("Make an Offering")
                        }

                        Text("Support places of practice, learning, and preservation")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                }
            }
        }
        .navigationTitle("Explore")
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct ExplorePlaceholderView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.weight(.semibold))

            Text("Coming soon")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text(subtitle)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
