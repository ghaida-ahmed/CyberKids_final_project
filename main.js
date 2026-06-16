document.addEventListener("DOMContentLoaded", () => {
  // Initialize Supabase
    var { SUPABASE_URL, SUPABASE_ANON_KEY } = window.CYBERKIDS_CONFIG;
    var supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  // DOM Elements
  const childBtn = document.getElementById('childBtn');
  const parentBtn = document.getElementById('parentBtn');
  const authForms = document.getElementById('authForms');
  const formTitle = document.getElementById('formTitle');

  const signupChildForm = document.getElementById('signupChildForm');
  const signupParentForm = document.getElementById('signupParentForm');
  const loginParentForm = document.getElementById('loginParentForm');

  const childOptions = document.getElementById('childOptions');
  const childSignUpBtn = document.getElementById('childSignUpBtn');
  const childLoginBtn = document.getElementById('childLoginBtn');
  const parentOptions = document.getElementById('parentOptions');
  const parentSignUpBtn = document.getElementById('parentSignUpBtn');
  const parentLoginBtn = document.getElementById('parentLoginBtn');

  // ===================== Child Buttons =====================
  childBtn.addEventListener('click', () => {
    document.getElementById('roleSelection').style.display = 'none';
    childOptions.style.display = 'block';
  });

  childSignUpBtn.addEventListener('click', () => {
    childOptions.style.display = 'none';
    authForms.style.display = 'block';
    formTitle.textContent = "Child Sign Up";
    signupChildForm.style.display = 'block';
    signupParentForm.style.display = 'none';
    loginParentForm.style.display = 'none';
  });

  childLoginBtn.addEventListener('click', () => {
    window.location.href = "childLogin.html";
  });

  // ===================== Parent Buttons =====================
  parentBtn.addEventListener("click", () => {
    document.getElementById('roleSelection').style.display = 'none';
    authForms.style.display = "block";
    formTitle.textContent = "Parent Options";
    document.getElementById("parentOptions").style.display = "block";
    signupChildForm.style.display = "none";
    loginParentForm.style.display = "none";
    signupParentForm.style.display = "none";
  });

  parentSignUpBtn.addEventListener("click", () => {
    formTitle.textContent = "Parent Sign Up";
    signupParentForm.style.display = "block";
    loginParentForm.style.display = "none";
    document.getElementById("parentOptions").style.display = "none";
  });

  parentLoginBtn.addEventListener("click", () => {
    formTitle.textContent = "Parent Login";
    loginParentForm.style.display = "block";
    signupParentForm.style.display = "none";
    document.getElementById("parentOptions").style.display = "none";
  });

  // ======= Parent Sign Up - UPDATED for 2 Children =======
  signupParentForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    const parentEmail = document.getElementById("ParentEmail").value.trim().toLowerCase();
    const parentPassword = document.getElementById("parentPassword").value.trim();
    
    // First child (required)
    const childEmail1 = document.getElementById("childEmailParent1").value.trim().toLowerCase();
    const childAge1 = document.getElementById("childAgeParent1").value;
    
    // Second child (optional)
    const childEmail2 = document.getElementById("childEmailParent2").value.trim().toLowerCase();
    const childAge2 = document.getElementById("childAgeParent2").value;

    // التحقق من أن البيانات الأساسية موجودة
    if (!parentEmail || !parentPassword || !childEmail1 || !childAge1) {
      alert("❌ Please fill in all required fields!");
      return;
    }

    // ✅ التحقق من الطفل الأول (إجباري)
    const { data: child1Data, error: child1Error } = await supabase
      .from("children")
      .select("email")
      .eq("email", childEmail1)
      .single();

    if (child1Error || !child1Data) {
      alert("❌ First child not found. Please make sure your first child has an account.");
      console.error("Child 1 error:", child1Error);
      return;
    }

    // ✅ التحقق من الطفل الثاني (اختياري)
    let child2Valid = false;
    if (childEmail2 && childEmail2.length > 0) {
      const { data: child2Data, error: child2Error } = await supabase
        .from("children")
        .select("email")
        .eq("email", childEmail2)
        .single();

      if (child2Error || !child2Data) {
        alert("⚠️ Second child email not found. Please verify the email or leave it empty.");
        console.error("Child 2 error:", child2Error);
        return;
      }
      child2Valid = true;
    }

    // ✅ إضافة حساب الوالد مع طفل واحد أو طفلين
    const parentData = {
      email: parentEmail,
      password: parentPassword,
      childEmail: childEmail1,
      childAge: parseInt(childAge1)
    };

    // إضافة الطفل الثاني إذا كان موجود
    if (child2Valid && childEmail2) {
      parentData.childemail2 = childEmail2;  // ✅ lowercase
      parentData.childage2 = parseInt(childAge2);  // ✅ lowercase
    }

    const { data, error } = await supabase.from("parents").insert([parentData]);

    if (error) {
      alert("❌ Error creating parent account!\n\nDetails: " + error.message + "\n\nCheck console for more info.");
      console.error("Full error details:", error);
      console.error("Error code:", error.code);
      console.error("Error hint:", error.hint);
      console.error("Error details:", error.details);
      return;
    }

    alert("✅ Parent account created successfully!");
    signupParentForm.reset();
    localStorage.setItem("parentEmail", parentEmail);
    window.location.href = "parentDashboard.html";
  });

  // ======= Parent Login =======
  loginParentForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    const email = document.getElementById("loginParentEmail").value.trim().toLowerCase();
    const password = document.getElementById("loginParentPassword").value.trim();

    const { data, error } = await supabase
      .from("parents")
      .select("*")
      .eq("email", email)
      .single();

    if (error || !data) {
      alert("❌ Account not found. Please sign up first.");
      return;
    }

    if (data.password !== password) {
      alert("❌ Incorrect password!");
      return;
    }

    localStorage.setItem("parentEmail", email);
    window.location.href = "parentDashboard.html";
  });

  // ===================== Child Sign Up =====================
  signupChildForm.addEventListener("submit", async (e) => {
    e.preventDefault();
    const firstName = document.getElementById("firstName").value;
    const lastName = document.getElementById("lastName").value;
    const email = document.getElementById("childEmail").value;
    const age = document.getElementById("childAge").value;
    const password = document.getElementById("childPassword").value;

    const { data, error } = await supabase
      .from("children")
      .insert([{ 
        firstName, 
        lastName, 
        email, 
        age: parseInt(age), 
        password, 
        progress: { "gamesCompleted": 0, "quizzesCompleted": 0, "lessonsCompleted": 0 },
        points: 0
      }]);

    if (error) return alert("Error: " + error.message);
    alert("Child registered successfully!");
    localStorage.setItem("childEmail", email);
    window.location.href = "childDashboard.html";
  });

  // ======= Back Buttons =======
  const backFromChildSignup = document.getElementById("backFromChildSignup");
  if (backFromChildSignup) {
    backFromChildSignup.addEventListener("click", () => {
      signupChildForm.style.display = "none";
      authForms.style.display = "none";
      childOptions.style.display = "block";
    });
  }

  const backFromParentLogin = document.getElementById("backFromParentLogin");
  const backFromParentSignup = document.getElementById("backFromParentSignup");

  if (backFromParentLogin) {
    backFromParentLogin.addEventListener("click", () => {
      loginParentForm.style.display = "none";
      document.getElementById("parentOptions").style.display = "block";
      formTitle.textContent = "Parent Options";
    });
  }

  if (backFromParentSignup) {
    backFromParentSignup.addEventListener("click", () => {
      signupParentForm.style.display = "none";
      document.getElementById("parentOptions").style.display = "block";
      formTitle.textContent = "Parent Options";
    });
  }
});
