// =============================================
// JAVASCRIPT PERSONALIZADO - SGI-GuateMart
// static/js/main.js
// =============================================

// Esperar a que el DOM esté cargado
document.addEventListener('DOMContentLoaded', function() {
    
    // Auto-cerrar alertas después de 5 segundos
    setTimeout(function() {
        let alerts = document.querySelectorAll('.alert:not(.alert-permanent)');
        alerts.forEach(function(alert) {
            let bsAlert = new bootstrap.Alert(alert);
            bsAlert.close();
        });
    }, 5000);
    
    // Confirmación para eliminaciones
    let deleteButtons = document.querySelectorAll('.btn-delete, [data-confirm-delete]');
    deleteButtons.forEach(function(button) {
        button.addEventListener('click', function(e) {
            if (!confirm('¿Está seguro de que desea eliminar este elemento?')) {
                e.preventDefault();
            }
        });
    });
    
    // Tooltips de Bootstrap
    let tooltipTriggerList = [].slice.call(document.querySelectorAll('[data-bs-toggle="tooltip"]'));
    tooltipTriggerList.map(function (tooltipTriggerEl) {
        return new bootstrap.Tooltip(tooltipTriggerEl);
    });
    
    // Formatear números como moneda
    let currencyElements = document.querySelectorAll('.currency');
    currencyElements.forEach(function(el) {
        let value = parseFloat(el.textContent);
        if (!isNaN(value)) {
            el.textContent = 'Q' + value.toFixed(2);
        }
    });
    
    // Búsqueda en tiempo real (debounce)
    let searchInputs = document.querySelectorAll('.search-input');
    searchInputs.forEach(function(input) {
        let timeout = null;
        input.addEventListener('input', function() {
            clearTimeout(timeout);
            timeout = setTimeout(function() {
                input.form.submit();
            }, 500);
        });
    });
    
});

// Función para mostrar loading en botones
function showLoading(button) {
    button.disabled = true;
    let originalText = button.innerHTML;
    button.setAttribute('data-original-text', originalText);
    button.innerHTML = '<span class="spinner-border spinner-border-sm me-2"></span>Cargando...';
}

// Función para ocultar loading en botones
function hideLoading(button) {
    button.disabled = false;
    let originalText = button.getAttribute('data-original-text');
    if (originalText) {
        button.innerHTML = originalText;
    }
}

// Función para formatear fecha
function formatDate(dateString) {
    let date = new Date(dateString);
    let day = String(date.getDate()).padStart(2, '0');
    let month = String(date.getMonth() + 1).padStart(2, '0');
    let year = date.getFullYear();
    return `${day}/${month}/${year}`;
}

// Función para formatear número como moneda
function formatCurrency(value) {
    return 'Q' + parseFloat(value).toFixed(2);
}

// Función para validar formulario
function validateForm(formId) {
    let form = document.getElementById(formId);
    if (form) {
        form.classList.add('was-validated');
        return form.checkValidity();
    }
    return false;
}

// Exportar funciones globales
window.SGI = {
    showLoading: showLoading,
    hideLoading: hideLoading,
    formatDate: formatDate,
    formatCurrency: formatCurrency,
    validateForm: validateForm
};

console.log('SGI-GuateMart JavaScript cargado correctamente');