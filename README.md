# Cyber Kids Academy

Cyber Kids Academy is a browser-based educational platform that helps children learn online safety through interactive games, quizzes, lessons, progress tracking, and role-based dashboards for children, parents, teachers, and administrators.

## Key Features

- Role-based entry points for children, parents, teachers, and administrators
- Child registration, login, progress tracking, and points
- Interactive cybersecurity games and quizzes
- Parent dashboard for monitoring progress, setting daily play limits, receiving activity notifications, and exporting PDF reports
- Teacher dashboard for viewing student progress and controlling visible learning content
- Admin dashboard for managing teacher accounts and submitting educational content ideas
- Supabase-backed data storage for users, progress, content visibility, play logs, and reports

## Technologies Used

- HTML5
- CSS3
- JavaScript
- Supabase JavaScript client
- Supabase database
- jsPDF for parent progress report exports

## Installation

1. Clone the repository:

   ```bash
   git clone https://github.com/YOUR-USERNAME/CyberKids.git
   cd CyberKids
   ```

2. Create your local configuration file:

   ```bash
   cp config.example.js config.js
   ```

3. Open `config.js` and add your Supabase project URL and anon key:

   ```js
   window.CYBERKIDS_CONFIG = {
     SUPABASE_URL: "https://your-project-ref.supabase.co",
     SUPABASE_ANON_KEY: "your-supabase-anon-key"
   };
   ```

4. Apply the database updates from `database/schema.sql` in your Supabase SQL editor.

5. Serve the project locally. A simple static server works well:

   ```bash
   python3 -m http.server 8000
   ```

6. Open the app at:

   ```text
   http://localhost:8000
   ```

## Usage

- Start from `index.html` and choose a role.
- Children can sign up, log in, play games, complete quizzes and lessons, and earn points.
- Parents can register with child accounts, review progress, set daily play limits, and download PDF reports.
- Teachers can review student progress and show or hide learning content.
- Admins can manage teacher accounts and submit ideas for future games, quizzes, and lessons.

## Folder Structure

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

## Screenshots

Screenshots can be added here after the application is deployed or captured locally.

## Live Demo

No live demo is currently configured. This project can be deployed as a static site through GitHub Pages, Netlify, or Vercel after adding a valid Supabase configuration.

## Future Improvements

- Replace plain-text password checks with Supabase Auth
- Add Row Level Security policies for every table before production use
- Move repeated inline scripts into shared JavaScript modules
- Add automated tests for authentication and progress flows
- Improve accessibility for keyboard and screen reader users
- Add screenshots and a hosted live demo link

## Security Notes

`config.js` is intentionally ignored by Git so API keys and project-specific settings are not committed. If a Supabase key was ever committed or pushed previously, rotate the key in Supabase and consider cleaning the Git history before making the repository public.
