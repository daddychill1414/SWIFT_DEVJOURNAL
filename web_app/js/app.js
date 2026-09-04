// DevJournal State & Service Handler
const DevJournalStore = {
    user: JSON.parse(localStorage.getItem('devjournal_user')) || { name: 'Raniel Go', email: 'raniel@devjournal.app', repoCount: 4 },
    journals: JSON.parse(localStorage.getItem('devjournal_entries')) || [
        { id: 1, title: "Implemented GitHub synchronization", content: "Built native URLSession integration with async/await and Keychain token storage.", date: "Today", mood: "😄", tags: ["github", "swift", "development"] },
        { id: 2, title: "Designed Glassmorphism UI System", content: "Created visionOS inspired ultraThinMaterial cards with soft stroke overlays.", date: "Yesterday", mood: "🤩", tags: ["swiftui", "design"] }
    ],
    projects: [
        { name: "DevJournal iOS", desc: "Native iOS app with SwiftData, Supabase, and GitHub Integration", category: "Personal Project", progress: 72, commits: 142 },
        { name: "Gameteract", desc: "Interactive Capstone project platform with real-time analytics", category: "Capstone Project", progress: 84, commits: 127 },
        { name: "OneNetworx", desc: "OJT Enterprise Network Monitoring Solution", category: "OJT Project", progress: 100, commits: 89 }
    ],
    saveJournals() {
        localStorage.setItem('devjournal_entries', JSON.stringify(this.journals));
    },
    saveUser(user) {
        this.user = user;
        localStorage.setItem('devjournal_user', JSON.stringify(user));
    }
};
