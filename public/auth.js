function login(email, password) {
	const credentials = btoa(email + ':' + password); // Base64 encode email and password

	fetch('/api/user/login', {
		method: 'POST',
		headers: {
			'Authorization': 'Basic ' + credentials,
			'Content-Type': 'application/json'
		},
		body: JSON.stringify({
			// Additional data if needed
		})
	}).then(response => {
		if (!response.ok) {
			throw new Error('Invalid credentials');
		}

		return response.json();
	}).then(data => {
		// Handle successful login response
		sessionStorage.setItem("sessionToken", data["token"]);

		//window.location.reload();
	}).catch(error => {
		// Handle error (e.g., display error message)
		document.getElementById('error-message').innerText = error.message;
	});
}
