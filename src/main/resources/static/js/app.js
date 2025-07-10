// Global variables
let currentColor = null;
let refreshInterval = null;

// Initialize the application
document.addEventListener('DOMContentLoaded', function() {
    loadAvailableColors();
    refreshAll();
    startAutoRefresh();
    updateCurrentTime();
    setInterval(updateCurrentTime, 1000);
});

// Load available colors for the dropdown
async function loadAvailableColors() {
    try {
        const response = await fetch('/api/colors/available');
        const colors = await response.json();

        const select = document.getElementById('color-select');
        select.innerHTML = '<option value="">Select a color...</option>';

        colors.forEach(color => {
            const option = document.createElement('option');
            option.value = color;
            option.textContent = color.charAt(0) + color.slice(1).toLowerCase();
            select.appendChild(option);
        });
    } catch (error) {
        console.error('Error loading available colors:', error);
        showNotification('Error loading available colors', 'error');
    }
}

// Set color manually
async function setColor() {
    const select = document.getElementById('color-select');
    const color = select.value;
    const publish = document.getElementById('publish-checkbox').checked;

    if (!color) {
        showNotification('Please select a color', 'warning');
        return;
    }

    try {
        const response = await fetch('/api/colors/set', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify({
                color: color,
                source: 'manual',
                publish: `${publish}`
            })
        });

        if (response.ok) {
            showNotification(`Color set to ${color}`, 'success');
            refreshAll();
            select.value = '';
        } else {
            showNotification('Error setting color', 'error');
        }
    } catch (error) {
        console.error('Error setting color:', error);
        showNotification('Error setting color', 'error');
    }
}

// Refresh all data
function refreshAll() {
    refreshTimeline();
    refreshEvents();
}

// Refresh timeline
async function refreshTimeline() {
    try {
        const [currentResponse, historyResponse] = await Promise.all([
            fetch('/api/colors/current'),
            fetch('/api/colors/history')
        ]);

        const current = await currentResponse.json();
        const history = await historyResponse.json();

        currentColor = current;
        updateCurrentColorBadge(current);
        renderTimeline(history);
    } catch (error) {
        console.error('Error refreshing timeline:', error);
        showNotification('Error loading timeline data', 'error');
    }
}

// Refresh events
async function refreshEvents() {
    try {
        const response = await fetch('/api/events');
        const events = await response.json();
        renderEvents(events);
    } catch (error) {
        console.error('Error refreshing events:', error);
        showNotification('Error loading events data', 'error');
    }
}

// Update current color badge
function updateCurrentColorBadge(colorChange) {
    const badge = document.getElementById('current-color-badge');
    const colorName = colorChange.color.charAt(0) + colorChange.color.slice(1).toLowerCase();
    const timeAgo = getTimeAgo(new Date(colorChange.timestamp));

    badge.innerHTML = `
        <span class="current-color-display color-${colorChange.color.toLowerCase()}"></span>
        ${colorName} (${timeAgo})
    `;
}

// Render timeline
function renderTimeline(history) {
    const container = document.getElementById('timeline-container');

    if (history.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No color changes yet</div>';
        return;
    }

    let html = '';
    history.forEach((change, index) => {
        const colorClass = `color-${change.color.toLowerCase()}`;
        const timeFormatted = formatDateTime(new Date(change.timestamp));
        const timeAgo = getTimeAgo(new Date(change.timestamp));
        const colorName = change.color.charAt(0) + change.color.slice(1).toLowerCase();

        html += `
            <div class="timeline-item">
                <div class="timeline-dot ${colorClass}"></div>
                <div class="timeline-content">
                    <div class="timeline-time">${timeFormatted} (${timeAgo})</div>
                    <div><strong>${colorName}</strong></div>
                    <div class="timeline-source">Source: ${change.source}</div>
                </div>
            </div>
        `;
    });

    container.innerHTML = html;
}

// Render events
function renderEvents(events) {
    const container = document.getElementById('events-container');

    if (events.length === 0) {
        container.innerHTML = '<div class="text-center text-muted">No events received yet</div>';
        return;
    }

    let html = '';
    events.forEach(event => {
        const timeFormatted = formatDateTime(new Date(event.timestamp));
        const timeAgo = getTimeAgo(new Date(event.timestamp));

        html += `
            <div class="event-item">
                <div class="event-header">
                    <div class="event-type">${event.eventType}</div>
                    <div class="event-time">${timeAgo}</div>
                </div>
                <div class="event-source">Source: ${event.source}</div>
                <div class="event-id">ID: ${event.eventId}</div>
                ${event.subject ? `<div class="event-subject">Subject: ${event.subject}</div>` : ''}
                ${event.data ? `<div class="event-data">${event.data}</div>` : ''}
            </div>
        `;
    });

    container.innerHTML = html;
}

// Auto-refresh functionality
function startAutoRefresh() {
    // Refresh every 5 seconds
    refreshInterval = setInterval(refreshAll, 5000);
}

function stopAutoRefresh() {
    if (refreshInterval) {
        clearInterval(refreshInterval);
        refreshInterval = null;
    }
}

// Utility functions
function formatDateTime(date) {
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: '2-digit',
        hour: '2-digit',
        minute: '2-digit',
        second: '2-digit'
    });
}

function getTimeAgo(date) {
    const now = new Date();
    const diffMs = now - date;
    const diffSecs = Math.floor(diffMs / 1000);
    const diffMins = Math.floor(diffSecs / 60);
    const diffHours = Math.floor(diffMins / 60);
    const diffDays = Math.floor(diffHours / 24);

    if (diffSecs < 60) {
        return `${diffSecs}s ago`;
    } else if (diffMins < 60) {
        return `${diffMins}m ago`;
    } else if (diffHours < 24) {
        return `${diffHours}h ago`;
    } else {
        return `${diffDays}d ago`;
    }
}

function updateCurrentTime() {
    const now = new Date();
    document.getElementById('current-time').textContent = formatDateTime(now);
}

function showNotification(message, type = 'info') {
    // Create a toast notification
    const toastContainer = document.getElementById('toast-container') || createToastContainer();

    const toast = document.createElement('div');
    toast.className = `toast align-items-center text-white bg-${type === 'error' ? 'danger' : type === 'success' ? 'success' : type === 'warning' ? 'warning' : 'primary'} border-0`;
    toast.setAttribute('role', 'alert');
    toast.innerHTML = `
        <div class="d-flex">
            <div class="toast-body">${message}</div>
            <button type="button" class="btn-close btn-close-white me-2 m-auto" data-bs-dismiss="toast"></button>
        </div>
    `;

    toastContainer.appendChild(toast);

    const bsToast = new bootstrap.Toast(toast);
    bsToast.show();

    // Remove toast element after it's hidden
    toast.addEventListener('hidden.bs.toast', () => {
        toast.remove();
    });
}

function createToastContainer() {
    const container = document.createElement('div');
    container.id = 'toast-container';
    container.className = 'toast-container position-fixed top-0 end-0 p-3';
    container.style.zIndex = '1050';
    document.body.appendChild(container);
    return container;
}

// Keyboard shortcuts
document.addEventListener('keydown', function(event) {
    if (event.ctrlKey || event.metaKey) {
        switch(event.key) {
            case 'r':
                event.preventDefault();
                refreshAll();
                showNotification('Data refreshed', 'info');
                break;
        }
    }
});
