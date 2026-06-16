# 🌐 Cyber Kids Academy

Cyber Kids Academy is an interactive web platform that teaches children practical online safety skills through games, quizzes, lessons, and role-based dashboards. The project is designed for children, parents, teachers, and administrators, combining playful learning with progress tracking and simple content management.

## ✨ Features

- **Role-based experience** for children, parents, teachers, and administrators
- **Child learning dashboard** with games, quizzes, lessons, points, and progress tracking
- **Interactive cybersecurity activities** focused on safe links, password strength, online choices, and digital safety habits
- **Parent dashboard** for monitoring child progress, setting daily play limits, receiving progress notifications, and exporting PDF reports
- **Teacher dashboard** for viewing student progress and managing visible learning content
- **Admin dashboard** for managing teacher accounts and submitting future content ideas
- **Supabase integration** for storing users, progress, content visibility, play logs, and dashboard data

## 🛠️ Technologies Used

- **HTML5** for page structure
- **CSS3** for responsive styling and visual design
- **JavaScript** for client-side interactivity and dashboard logic
- **Supabase** for backend data storage
- **Supabase JavaScript Client** for database communication
- **jsPDF** for downloadable parent progress reports

## 🚀 Installation

Clone the repository:

```bash
git clone https://github.com/ghaida-ahmed/CyberKids_final_project.git
cd CyberKids_final_project
```

Create a local configuration file:

```bash
cp config.example.js config.js
```

Add your Supabase project URL and anon key to `config.js`:

```js
window.CYBERKIDS_CONFIG = {
  SUPABASE_URL: "https://your-project-ref.supabase.co",
  SUPABASE_ANON_KEY: "your-supabase-anon-key"
};
```

Apply the database schema in Supabase:

```text
database/schema.sql
```

Start a local static server:

```bash
python3 -m http.server 8000
```

Open the project in your browser:

```text
http://localhost:8000
```

## 📖 Usage

- Open `index.html` and select a role.
- Children can create accounts, log in, complete learning activities, and earn points.
- Parents can connect to child accounts, review progress, set play limits, and download progress reports.
- Teachers can review student progress and manage which learning content is visible.
- Administrators can create teacher accounts and submit new educational content ideas.

## 📁 Folder Structure

```text
.
├── README.md
├── .gitignore
├── config.example.js
├── database/
│   └── schema.sql
├── index.html
├── main.js
├── style.css
├── childLogin.html
├── childDashboard.html
├── parentDashboard.html
├── teacherLogin.html
├── teacherDashboard.html
├── adminLogin.html
├── adminDashboard.html
├── game1.html
├── game2.html
├── game3.html
├── quiz1.html
├── quiz2.html
└── lesson1.html
```

## 🔮 Future Improvements

- Replace custom password checks with Supabase Auth
- Add Row Level Security policies for production-ready access control
- Move repeated inline scripts into reusable JavaScript modules
- Add automated tests for authentication, progress tracking, and dashboard flows
- Improve keyboard navigation and screen reader accessibility
- Add a deployed production version with real environment-based configuration

## 🔐 Security Notes

- `config.js` is ignored by Git and should contain local Supabase configuration only.
- `.env` files are ignored to prevent accidental exposure of credentials.
- `config.example.js` contains placeholders only and is safe to commit.
- Production deployments should use Supabase Auth, strong database policies, and rotated keys when needed.
