document.addEventListener("DOMContentLoaded", () => {
  // Initialize Supabase
    var { SUPABASE_URL, SUPABASE_ANON_KEY } = window.CYBERKIDS_CONFIG;
    var supabase = window.supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

  function friendlyAuthMessage(error) {
    if (!error) return "Something went wrong. Please try again.";
    const message = (error.message || "").toLowerCase();
    if (message.includes("already registered") || message.includes("already exists")) {
      return "An account already exists with this email. Please log in instead.";
    }
    if (message.includes("invalid login credentials")) {
      return "Invalid email or password.";
    }
    if (message.includes("rate limit") || message.includes("too many") || message.includes("email rate")) {
      return "Too many signup emails were sent. Please wait a while before trying again, or turn off email confirmation while testing locally.";
    }
    if (message.includes("password")) {
      return "Please use a stronger password.";
    }
    if (message.includes("database") || message.includes("child_email_not_found")) {
      return "Please make sure the child email belongs to an existing child account, then try again.";
    }
    return "We couldn't complete that request. Please check your details and try again.";
  }

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
      alert("Please fill in all required fields.");
      return;
    }

    if (parentEmail === childEmail1 || (childEmail2 && parentEmail === childEmail2)) {
      alert("Parent email must be different from the child email. Use your own parent email, then enter the child email in the child field.");
      return;
    }

    const { data: firstChildExists, error: firstChildCheckError } = await supabase
      .rpc("child_account_exists", { child_email: childEmail1 });

    if (firstChildCheckError || !firstChildExists) {
      alert("First child account not found. Please make sure your child signs up first, then use the same child email here.");
      console.error("First child lookup error:", firstChildCheckError);
      return;
    }

    if (childEmail2) {
      const { data: secondChildExists, error: secondChildCheckError } = await supabase
        .rpc("child_account_exists", { child_email: childEmail2 });

      if (secondChildCheckError || !secondChildExists) {
        alert("Second child account not found. Please check the email or leave the second child fields empty.");
        console.error("Second child lookup error:", secondChildCheckError);
        return;
      }
    }

    const { data, error } = await supabase.auth.signUp({
      email: parentEmail,
      password: parentPassword,
      options: {
        emailRedirectTo: `${window.location.origin}/index.html`,
        data: {
          role: "parent",
          childEmail: childEmail1,
          childAge: String(childAge1),
          childEmail2: childEmail2 || "",
          childAge2: childAge2 || ""
        }
      }
    });

    if (error) {
      alert(friendlyAuthMessage(error));
      console.error("Parent signup error:", error);
      return;
    }

    if (data.user && Array.isArray(data.user.identities) && data.user.identities.length === 0) {
      alert("An account already exists with this parent email. Please log in instead, or use a different parent email.");
      return;
    }

    if (!data.session) {
      alert("Parent account created. Please check your email to confirm your account, then log in.");
      signupParentForm.reset();
      return;
    }

    alert("Parent account created successfully.");
    signupParentForm.reset();
    localStorage.setItem("parentEmail", parentEmail);
    localStorage.setItem("userRole", "parent");
    window.location.href = "parentDashboard.html";
  });

  // ======= Parent Login =======
  loginParentForm.addEventListener("submit", async (e) => {
    e.preventDefault();

    const email = document.getElementById("loginParentEmail").value.trim().toLowerCase();
    const password = document.getElementById("loginParentPassword").value.trim();

    const { data, error } = await supabase.auth.signInWithPassword({ email, password });

    if (error || !data.session) {
      alert(friendlyAuthMessage(error));
      return;
    }

    const { data: profile, error: profileError } = await supabase
      .from("profiles")
      .select("role")
      .eq("id", data.user.id)
      .single();

    if (profileError || profile?.role !== "parent") {
      await supabase.auth.signOut();
      alert("This account is not a parent account.");
      return;
    }

    localStorage.setItem("parentEmail", email);
    localStorage.setItem("userRole", "parent");
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

    const { data, error } = await supabase.auth.signUp({
      email: email.trim().toLowerCase(),
      password,
      options: {
        emailRedirectTo: `${window.location.origin}/childLogin.html`,
        data: {
          role: "child",
          firstName,
          lastName,
          age: String(age)
        }
      }
    });

    if (error) {
      alert(friendlyAuthMessage(error));
      console.error("Child signup error:", error);
      return;
    }

    if (data.user && Array.isArray(data.user.identities) && data.user.identities.length === 0) {
      alert("An account already exists with this child email. Please log in instead.");
      return;
    }

    if (!data.session) {
      alert("Child account created. Please check your email to confirm your account, then log in.");
      signupChildForm.reset();
      return;
    }

    alert("Child registered successfully!");
    localStorage.setItem("childEmail", email.trim().toLowerCase());
    localStorage.setItem("userRole", "child");
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
