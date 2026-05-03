(function () {
    const shop          = document.getElementById('shop');
    const closeBtn      = document.getElementById('closeBtn');
    const repLabel      = document.getElementById('repLabel');
    const repBadge      = document.getElementById('repBadge');
    const repProgressText = document.getElementById('repProgressText');
    const repBarFill    = document.getElementById('repBarFill');

    const weaponsGrid   = document.getElementById('weaponsGrid');
    const ammoGrid      = document.getElementById('ammoGrid');
    const tabs          = document.querySelectorAll('.tab');

    // Widget elements
    const armsWidget       = document.getElementById('armsWidget');
    const armsWidgetTimer  = document.getElementById('armsWidgetTimer');
    const armsWidgetStatus = document.getElementById('armsWidgetStatus');
    const armsWidgetSub    = document.getElementById('armsWidgetSub');

    let currentTier     = 1;
    let currentPurchases = 0;
    let currentNextTierAt = null;

    // ─── Rotation countdown state ─────────────────────────────────
    // Server tells us a unix timestamp (in ms) when the next rotation
    // happens. We tick locally every second.
    let nextRotateAt = null;

    // ─── Helpers ──────────────────────────────────────────────────

    function fmtMoney(n) {
        return '$' + (n || 0).toLocaleString();
    }

    function applyRep(data) {
        currentTier = data.repTier || 1;
        currentPurchases = data.purchases || 0;
        currentNextTierAt = data.nextTierAt;

        if (data.repTierLabel) repLabel.textContent = data.repTierLabel;
        if (data.repTierColor) {
            repLabel.style.color = data.repTierColor;
            repBadge.style.borderColor = data.repTierColor + '66';
            repBadge.style.background  = data.repTierColor + '1f';
        }

        if (currentNextTierAt) {
            const remaining = currentNextTierAt - currentPurchases;
            repProgressText.textContent =
                currentPurchases + ' purchases · ' + Math.max(0, remaining) + ' to next rank';
            const pct = Math.min(100, (currentPurchases / currentNextTierAt) * 100);
            repBarFill.style.width = pct + '%';
        } else {
            repProgressText.textContent = currentPurchases + ' purchases · max rank';
            repBarFill.style.width = '100%';
        }
    }

    // ─── Render cards ─────────────────────────────────────────────

    function tierClass(tier) { return 't' + tier; }

    function renderCard(entry, kind) {
        const isLocked = currentTier < entry.tier;

        const card = document.createElement('div');
        card.className = 'item-card' + (isLocked ? ' locked' : '');

        const accountText = entry.payAccount === 'dirty' ? 'Dirty Money' : 'Cash';

        card.innerHTML = `
            <div class="item-row">
                <div>
                    <div class="item-name">${entry.label}</div>
                    <div class="item-cat">${entry.category || ''}</div>
                </div>
                <span class="item-tier ${tierClass(entry.tier)}">Tier ${entry.tier}</span>
            </div>
            <div class="item-desc">${entry.description || ''}</div>
            <div class="item-footer">
                <div class="item-price">
                    <span class="price-value">${fmtMoney(entry.price)}</span>
                    <span class="price-account ${entry.payAccount === 'dirty' ? 'dirty' : 'cash'}">${accountText}</span>
                </div>
                ${isLocked
                    ? `<span class="locked-label">🔒 Locked</span>`
                    : `<button class="buy-btn" data-item="${entry.item}" data-kind="${kind}">Buy</button>`
                }
            </div>
        `;

        const btn = card.querySelector('.buy-btn');
        if (btn) {
            btn.addEventListener('click', () => onPurchase(entry.item, kind, btn));
        }

        return card;
    }

    function renderGrids(catalog, ammo) {
        weaponsGrid.innerHTML = '';
        ammoGrid.innerHTML = '';

        (catalog || []).forEach(e => weaponsGrid.appendChild(renderCard(e, 'weapon')));
        (ammo    || []).forEach(e => ammoGrid.appendChild(renderCard(e, 'ammo')));
    }

    // ─── Purchase flow ────────────────────────────────────────────

    async function onPurchase(item, kind, btnEl) {
        btnEl.disabled = true;
        btnEl.textContent = '...';

        try {
            const res = await fetch(`https://${GetParentResourceName()}/purchase`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ item, kind })
            });
            const data = await res.json();

            if (data && data.success) {
                btnEl.textContent = 'Purchased';
                btnEl.style.color = '#4ade80';
                btnEl.style.borderColor = 'rgba(74, 222, 128, 0.4)';
                btnEl.style.background = 'rgba(74, 222, 128, 0.15)';

                applyRep({
                    repTier: data.repTier,
                    repTierLabel: data.repTierLabel,
                    repTierColor: data.repTierColor,
                    purchases: data.purchases,
                    nextTierAt: data.nextTierAt,
                });

                // Re-render in case of tier-up
                if (data.tierUp && lastCatalog) {
                    setTimeout(() => renderGrids(lastCatalog, lastAmmo), 600);
                }

                setTimeout(() => {
                    btnEl.textContent = 'Buy';
                    btnEl.style.color = '';
                    btnEl.style.borderColor = '';
                    btnEl.style.background = '';
                    btnEl.disabled = false;
                }, 1500);
            } else {
                btnEl.textContent = (data && data.reason) || 'Failed';
                btnEl.style.color = '#ff6c6c';
                btnEl.style.borderColor = 'rgba(255, 60, 60, 0.4)';
                setTimeout(() => {
                    btnEl.textContent = 'Buy';
                    btnEl.style.color = '';
                    btnEl.style.borderColor = '';
                    btnEl.disabled = false;
                }, 2200);
            }
        } catch (err) {
            btnEl.textContent = 'Error';
            btnEl.disabled = false;
        }
    }

    // ─── Tabs ─────────────────────────────────────────────────────

    tabs.forEach(tab => {
        tab.addEventListener('click', () => {
            tabs.forEach(t => t.classList.remove('active'));
            tab.classList.add('active');

            const which = tab.getAttribute('data-tab');
            if (which === 'weapons') {
                weaponsGrid.classList.remove('hidden');
                ammoGrid.classList.add('hidden');
            } else {
                ammoGrid.classList.remove('hidden');
                weaponsGrid.classList.add('hidden');
            }
        });
    });

    // ─── Close ────────────────────────────────────────────────────

    function closeShop() {
        shop.classList.add('hidden');
        fetch(`https://${GetParentResourceName()}/close`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: '{}'
        });
    }

    closeBtn.addEventListener('click', closeShop);

    document.addEventListener('keydown', (e) => {
        if (e.key === 'Escape') closeShop();
    });

    // ─── Message handler ──────────────────────────────────────────

    let lastCatalog = null;
    let lastAmmo = null;

    window.addEventListener('message', (event) => {
        const data = event.data || {};

        if (data.action === 'show') {
            applyRep(data);
            lastCatalog = data.catalog;
            lastAmmo    = data.ammo;
            renderGrids(data.catalog, data.ammo);
            shop.classList.remove('hidden');

            // Reset tabs to weapons
            tabs.forEach(t => t.classList.remove('active'));
            document.querySelector('.tab[data-tab="weapons"]').classList.add('active');
            weaponsGrid.classList.remove('hidden');
            ammoGrid.classList.add('hidden');
        }

        if (data.action === 'hide') {
            shop.classList.add('hidden');
        }

        // Widget control — sent by client.lua on resource start and on rotation
        if (data.action === 'widgetSync') {
            if (typeof data.nextRotateAt === 'number') {
                nextRotateAt = data.nextRotateAt;
                armsWidget.classList.remove('hidden');
            }
        }

        if (data.action === 'widgetHide') {
            armsWidget.classList.add('hidden');
        }
    });

    // ─── Widget tick (1Hz) ────────────────────────────────────────

    function pad(n) { return n < 10 ? '0' + n : '' + n; }

    function fmtCountdown(secondsLeft) {
        if (secondsLeft < 0) secondsLeft = 0;
        const h = Math.floor(secondsLeft / 3600);
        const m = Math.floor((secondsLeft % 3600) / 60);
        const s = secondsLeft % 60;
        return pad(h) + ':' + pad(m) + ':' + pad(s);
    }

    setInterval(() => {
        if (nextRotateAt == null) return;

        const now = Date.now();
        const secondsLeft = Math.floor((nextRotateAt - now) / 1000);

        armsWidgetTimer.textContent = fmtCountdown(secondsLeft);
        armsWidgetStatus.textContent = 'DEALER LIVE';
        armsWidgetSub.textContent = 'until relocation';

        // Color states
        armsWidget.classList.remove('warning', 'critical');
        if (secondsLeft <= 60)        armsWidget.classList.add('critical');
        else if (secondsLeft <= 300)  armsWidget.classList.add('warning');
    }, 1000);
})();
