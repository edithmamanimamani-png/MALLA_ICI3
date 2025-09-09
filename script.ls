// ====== Config ======
const S_MAX = 12; // número de semestres a mostrar

// ====== Elementos ======
const grid = document.getElementById('grid');
const search = document.getElementById('search');
const filter = document.getElementById('filter-area');
const clearBtn = document.getElementById('clear');

let courses = [];
let idxByCode = new Map();

// ====== Render de columnas por semestre ======
function makeSemesters(){
  grid.innerHTML = '';
  for (let s=1; s<=S_MAX; s++){
    const sec = document.createElement('section');
    sec.className = 'semester';
    sec.dataset.semester = s;
    sec.innerHTML = `<h2>Semestre ${s}</h2><div class="col"></div>`;
    grid.appendChild(sec);
  }
}

function badge(text, cls=''){
  const span = document.createElement('span');
  span.className = `badge ${cls}`.trim();
  span.textContent = text;
  return span;
}

function render(){
  makeSemesters();
  const q = (search.value||'').trim().toLowerCase();
  const fa = filter.value;

  const list = courses
    .filter(c => (!fa || c.area === fa) &&
                 (!q || c.code.toLowerCase().includes(q) || c.name.toLowerCase().includes(q)))
    .sort((a,b)=> (a.semester-b.semester) || a.code.localeCompare(b.code,'es'));

  for (const c of list){
    const card = document.createElement('article');
    card.className = 'card';
    card.dataset.code = c.code;

    const code = document.createElement('div'); code.className='code'; code.textContent = c.code;
    const name = document.createElement('div'); name.className='name'; name.textContent = c.name;

    const badges = document.createElement('div'); badges.className='badges';
    const area = badge(c.area, `area ${c.area}`); badges.appendChild(area);
    if (c.hours !== undefined) badges.appendChild(badge(`${c.hours} h`));
    badges.appendChild(badge(`S${c.semester}`,'accent'));
    if (Array.isArray(c.prereq) && c.prereq.length) badges.appendChild(badge(`Pre: ${c.prereq.join(', ')}`));

    card.append(code,name,badges);
    card.addEventListener('click', ()=> focusCourse(c.code));

    const col = document.querySelector(`.semester[data-semester="${c.semester}"] .col`);
    (col || document.querySelector('.semester:last-child .col')).appendChild(card);
  }
}

function focusCourse(code){
  document.querySelectorAll('.card').forEach(el => el.classList.remove('highlight','prereq'));
  const target = document.querySelector(`.card[data-code="${CSS.escape(code)}"]`);
  if (!target) return;
  target.classList.add('highlight');

  const c = idxByCode.get(code);
  (c.prereq || []).forEach(p => {
    const el = document.querySelector(`.card[data-code="${CSS.escape(p)}"]`);
    if (el) el.classList.add('prereq');
  });

  showDetails(c);
}

let detailsEl;
function showDetails(c){
  if (!detailsEl){
    detailsEl = document.createElement('aside');
    detailsEl.className = 'details';
    document.body.appendChild(detailsEl);
  }
  detailsEl.innerHTML = `
    <h3>${c.code} — ${c.name}</h3>
    <div class="kv"><strong>Área:</strong> ${c.area}</div>
    <div class="kv"><strong>Semestre:</strong> ${c.semester}</div>
    ${c.hours!==undefined ? `<div class="kv"><strong>Horas:</strong> ${c.hours}</div>` : ''}
    ${c.prereq?.length ? `<div class="kv"><strong>Prerrequisitos:</strong> ${c.prereq.join(', ')}</div>` : '<div class="kv"><em>Sin prerrequisitos</em></div>'}
  `;
}

// ====== Carga de datos ======
function load(){
  fetch('data/courses.json', {cache:'no-store'})
    .then(r => {
      if(!r.ok) throw new Error(`HTTP ${r.status}`);
      return r.json();
    })
    .then(data => {
      courses = Array.isArray(data) ? data : [];
      idxByCode = new Map(courses.map(c => [c.code, c]));
      render();
    })
    .catch(err => {
      console.error('No se pudo cargar data/courses.json', err);
      grid.innerHTML = `<div style="padding:1rem">⚠️ No se pudo cargar <code>data/courses.json</code>. Revisa la ruta y el formato JSON.</div>`;
    });
}

// ====== Eventos UI ======
search.addEventListener('input', render);
filter.addEventListener('change', render);
clearBtn.addEventListener('click', ()=>{ search.value=''; filter.value=''; render(); });

// ====== Init ======
makeSemesters();
load();
