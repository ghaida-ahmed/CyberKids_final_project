(function () {
  const path = window.location.pathname.split("/").pop() || "index.html";
  const pageTitles = {
    "index.html": "Cyber Kids Academy",
    "childLogin.html": "Child Login",
    "adminLogin.html": "Admin Login",
    "teacherLogin.html": "Teacher Login",
    "childDashboard.html": "Child Dashboard",
    "parentDashboard.html": "Parent Dashboard",
    "teacherDashboard.html": "Teacher Dashboard",
    "adminDashboard.html": "Admin Dashboard",
    "game1.html": "Safe Links Game",
    "game2.html": "Password Challenge",
    "game3.html": "Quick Choice Game",
    "quiz1.html": "Safety Quiz",
    "quiz2.html": "Safety Quiz",
    "lesson1.html": "Online Safety Lesson"
  };

  const childPages = ["childDashboard.html", "game1.html", "game2.html", "game3.html", "quiz1.html", "quiz2.html", "lesson1.html"];
  const loginPages = ["index.html", "childLogin.html", "adminLogin.html", "teacherLogin.html"];
  const isLoginPage = loginPages.includes(path);

  function dashboardHref() {
    if (path === "adminDashboard.html") return "adminDashboard.html";
    if (path === "teacherDashboard.html") return "teacherDashboard.html";
    if (path === "parentDashboard.html") return "parentDashboard.html";
    if (childPages.includes(path)) return "childDashboard.html";
    return "index.html";
  }

  function loginHref() {
    if (path === "adminDashboard.html") return "adminLogin.html";
    if (path === "teacherDashboard.html") return "teacherLogin.html";
    if (path === "parentDashboard.html") return "index.html";
    if (childPages.includes(path)) return "childLogin.html";
    return "index.html";
  }

  async function signOut() {
    try {
      if (window.supabase?.auth?.signOut) {
        await window.supabase.auth.signOut();
      } else if (window.supabaseClient?.auth?.signOut) {
        await window.supabaseClient.auth.signOut();
      } else if (window.supabase?.createClient && window.CYBERKIDS_CONFIG) {
        const client = window.supabase.createClient(
          window.CYBERKIDS_CONFIG.SUPABASE_URL,
          window.CYBERKIDS_CONFIG.SUPABASE_ANON_KEY
        );
        await client.auth.signOut();
      }
    } catch (error) {
      console.error(error);
    }

    ["childEmail", "parentEmail", "teacherEmail", "adminEmail", "userRole"].forEach((key) => {
      localStorage.removeItem(key);
    });
    window.location.href = loginHref();
  }

  const header = document.createElement("header");
  header.className = "site-header";
  header.innerHTML = `
    <a class="site-brand" href="index.html" aria-label="Cyber Kids Academy home">
      <span class="brand-mark" aria-hidden="true">CK</span>
      <span>Cyber Kids Academy</span>
    </a>
    <nav class="site-nav" aria-label="Main navigation">
      ${path !== "index.html" ? '<a href="index.html">Home</a>' : ""}
      ${!isLoginPage ? `<a href="${dashboardHref()}">Dashboard</a>` : ""}
      ${!isLoginPage ? '<button type="button" class="nav-logout">Logout</button>' : ""}
    </nav>
  `;
  document.body.prepend(header);

  const logoutButton = header.querySelector(".nav-logout");
  if (logoutButton) {
    logoutButton.addEventListener("click", signOut);
  }

  if (!document.querySelector("footer")) {
    const footer = document.createElement("footer");
    footer.innerHTML = `
      <div class="footer-content">
        <div class="footer-section">
          <h3>${pageTitles[path] || "Cyber Kids Academy"}</h3>
          <p>Friendly online safety learning for children, parents, teachers, and admins.</p>
        </div>
        <div class="footer-section">
          <h3>Learning Space</h3>
          <p>Practice safe choices, track progress, and keep every account in the right place.</p>
        </div>
      </div>
      <div class="footer-bottom">Cyber Kids Academy</div>
    `;
    document.body.appendChild(footer);
  }
})();
