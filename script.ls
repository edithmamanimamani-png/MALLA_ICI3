// Malla interactiva simple (sin librerías)
const S_MAX = 12; // semestres

const grid = document.getElementById('grid');
const search = document.getElementById('search');
const filter = document.getElementById('filter-area');
const clearBtn = document.getElementById('clear');

let courses = [];
let idxByCode = new Map();

function makeSemesters(){
  grid.innerHTML = '';
  for(let s=1; s<=S_MAX; s++){
    const col = document.createElement('section');
    col.className = 'semester';
    col.dataset.semester = s;
    const h = document.createElement('h2');
    h.textContent = `Semestre ${s}`;
    const div = document.createElement('div');
    div.className = 'col';
    col.appendChild(h);
    col.appendChild(div);
    grid.appendChild(col);
  }
}

function badge(txt, cls=''){
  const span = document.createElement('span');
  span.className = `badge ${cls}`.trim();
  span.textContent = txt;
  return span;
}

function render(){
  makeSemesters();
  const q = (search.value || '').trim().toLowerCase();
  const fa = filter.value;

  document.querySelectorAll('.semester .col').forEach(el => el.innerHTML='');

  let visible = courses.filter(c => {
    const okArea = !fa || c.area === fa;
    const okText = !q || c.code.toLowerCase().includes(q) || c.name.toLowerCase().includes(q);
    return okArea && okText;
  });

  visible.sort((a,b)=> a.code.localeCompare(b.code, 'es'));

  visible.forEach(c => {
    const card = document.createElement('article');
    card.className = 'card';
    card.dataset.code = c.code;

    const code = document.createElement('div');
    code.className = 'code'; code.textContent = c.code;

    const name = document.createElement('div');
    name.className = 'name'; name.textContent = c.name;

    const badges = document.createElement('div');
    badges.className = 'badges';
    badges.appendChild(badge(c.area));
    if (c.hours) badges.appendChild(badge(`${c.hours} h`));
    badges.appendChild(badge(`S${c.semester}`,'accent'));
    if (c.prereq?.length) badges.appendChild(badge(`Pre: ${c.prereq.join(', ')}`));

    card.appendChild(code);
    card.appendChild(name);
    card.appendChild(badges);

    card.addEventListener('click', () => focusCourse(c.code));

    const col = document.querySelector(`.semester[data-semester="${c.semester}"] .col`);
    if (col) col.appendChild(card);
  });
}

function focusCourse(code){
  document.querySelectorAll('.card').forEach(el => el.classList.remove('highlight','prereq'));
  const target = document.querySelector(`.card[data-code="${CSS.escape(code)}"]`);
  if (!target) return;
  target.classList.add('highlight');

  const c = idxByCode.get(code);
  (c.prereq || []).forEach(p => {
    const pr = document.querySelector(`.card[data-code="${CSS.escape(p)}"]`);
    if (pr) pr.classList.add('prereq');
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
    ${c.hours ? `<div class="kv"><strong>Horas:</strong> ${c.hours}</div>` : ''}
    ${c.prereq?.length ? `<div class="kv"><strong>Prerrequisitos:</strong> ${c.prereq.join(', ')}</div>` : ''}
    ${c.notes ? `<p>${c.notes}</p>` : ''}
  `;
}

function load(){
  fetch('data/courses.json', {cache:'no-store'})
    .then(r => r.json())
    .then(data => {
      courses = data;
      idxByCode = new Map(courses.map(c => [c.code, c]));
      render();
    })
    .catch(err => {
      console.error('No se pudo cargar data/courses.json', err);
      courses = [];
      render();
    });
}

search.addEventListener('input', render);
filter.addEventListener('change', render);
clearBtn.addEventListener('click', () => { search.value=''; filter.value=''; render(); });

makeSemesters();
load();
