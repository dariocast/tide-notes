const STORAGE_KEY = "atlas-workspace-v1";
const daysAgo = (days, hour) => { const date = new Date(); date.setDate(date.getDate() - days); date.setHours(hour, 15, 0, 0); return date.toISOString(); };
const seed = [
  {id:"1",type:"note",title:"The shape of a personal knowledge space",content:"The best tools disappear while you think. Structure should emerge from the things you care about — not ask you to maintain another filing system.",tags:["product","attention"],createdAt:daysAgo(0,9)},
  {id:"2",type:"project",title:"Atlas — first principles",content:"A calm, connected workspace for turning fragments into durable ideas.",tags:["in progress"],createdAt:daysAgo(1,11)},
  {id:"3",type:"source",title:"The extended mind",content:"Notes on how tools become part of the thinking process.",tags:["research"],createdAt:daysAgo(1,10)},
  {id:"4",type:"person",title:"Andy Matuschak",content:"Evergreen notes, associative memory and interfaces for thought.",tags:["people"],createdAt:daysAgo(2,15)},
  {id:"5",type:"task",title:"Review the object model",content:"Define the smallest useful schema before adding sync or AI.",tags:["open"],createdAt:daysAgo(2,9)}
];
let objects = loadWorkspace();
let activeView = "today";
let activeType = "all";
let editingId = null;
const $ = (selector) => document.querySelector(selector);
const $$ = (selector) => [...document.querySelectorAll(selector)];

function loadWorkspace(){
  try { const saved = JSON.parse(localStorage.getItem(STORAGE_KEY)); return Array.isArray(saved) ? saved : seed; }
  catch { return seed; }
}
function persist(){ localStorage.setItem(STORAGE_KEY, JSON.stringify(objects)); }
function uid(){ return crypto.randomUUID ? crypto.randomUUID() : `${Date.now()}-${Math.random()}`; }
function label(type){ return type.charAt(0).toUpperCase() + type.slice(1); }
function formatDate(value){
  const date = new Date(value), now = new Date();
  if (date.toDateString() === now.toDateString()) return date.toLocaleTimeString([], {hour:"2-digit", minute:"2-digit"});
  return date.toLocaleDateString([], {month:"short", day:"numeric"});
}
function isToday(value){ return new Date(value).toDateString() === new Date().toDateString(); }
function visibleObjects(){
  let result = [...objects];
  if(activeView === "today") result = result.filter(object => isToday(object.createdAt));
  if(activeView === "inbox") result = result.filter(object => object.tags.includes("inbox"));
  if(activeType !== "all") result = result.filter(object => object.type === activeType);
  return result.sort((a,b) => new Date(b.createdAt) - new Date(a.createdAt));
}
function render(){
  const list = visibleObjects(), grid = $("#object-grid");
  $("#eyebrow").textContent = new Date().toLocaleDateString([], {weekday:"long", day:"numeric", month:"long"});
  $("#object-count").textContent = `${objects.length} object${objects.length === 1 ? "" : "s"}`;
  $("#today-count").textContent = objects.filter(o => isToday(o.createdAt)).length;
  $("#inbox-count").textContent = objects.filter(o => o.tags.includes("inbox")).length;
  $("#library-count").textContent = objects.length;
  $("#view-title").textContent = activeView === "today" ? "Today" : label(activeView);
  $("#breadcrumb").innerHTML = `Workspace / <strong>${label(activeView)}</strong>`;
  grid.replaceChildren();
  if(!list.length){ grid.innerHTML = '<div class="empty"><strong>No objects here yet.</strong>Capture a thought above or create your first object.</div>'; }
  list.forEach((object,index) => grid.appendChild(card(object,index === 0 && activeView === "today")));
  renderContext(list);
}
function card(object, featured){
  const node = $("#object-card-template").content.firstElementChild.cloneNode(true);
  if(featured) node.classList.add("featured");
  node.querySelector(".type").textContent = `${label(object.type)} · ${object.tags[0] || "Workspace"}`;
  node.querySelector("time").textContent = formatDate(object.createdAt);
  node.querySelector("h3").textContent = object.title;
  node.querySelector("p").textContent = object.content || "No content yet.";
  const tags = node.querySelector(".tags");
  object.tags.forEach(tag => { const span=document.createElement("span"); span.className="tag"+(tag === "product" || tag === "research" ? " link" : ""); span.textContent=`#${tag}`; tags.appendChild(span); });
  node.querySelector(".card-open").addEventListener("click", () => openEditor(object.id));
  return node;
}
function renderContext(list){
  const context = $("#context-list"); context.replaceChildren();
  list.slice(0,3).forEach(object => { const item=document.createElement("div"); item.className="relation"; item.innerHTML=`<i class="dot"></i><div><strong></strong><span>${label(object.type)} · ${formatDate(object.createdAt)}</span></div>`; item.querySelector("strong").textContent=object.title; context.appendChild(item); });
  if(!list.length) context.innerHTML='<p class="search-empty">No related objects yet.</p>';
}
function createObject(data){
  const object={id:uid(),type:data.type||"note",title:data.title.trim(),content:(data.content||"").trim(),tags:(data.tags||[]).map(tag=>tag.trim().toLowerCase()).filter(Boolean),createdAt:new Date().toISOString()};
  objects.unshift(object); persist(); render(); return object;
}
function updateObject(id,data){
  const index=objects.findIndex(object=>object.id===id); if(index<0) return;
  objects[index]={...objects[index],...data,title:data.title.trim(),content:(data.content||"").trim(),tags:(data.tags||[]).map(tag=>tag.trim().toLowerCase()).filter(Boolean)}; persist(); render();
}
function openEditor(id=null){
  editingId=id; const object=objects.find(item=>item.id===id); $("#editor-title").textContent=object?"Edit object":"New object"; $("#object-type").value=object?.type||"note"; $("#object-title").value=object?.title||""; $("#object-content").value=object?.content||""; $("#object-tags").value=object?.tags?.join(", ")||""; $("#editor-modal").hidden=false; setTimeout(()=>$("#object-title").focus(),20);
}
function closeEditor(){ $("#editor-modal").hidden=true; editingId=null; $("#editor-form").reset(); }
function searchObjects(query){ const term=query.trim().toLowerCase(); return term ? objects.filter(object=>[object.title,object.content,...object.tags].join(" ").toLowerCase().includes(term)) : objects; }
function openSearch(){ $("#search-modal").hidden=false; $("#search-input").value=""; renderSearch(); setTimeout(()=>$("#search-input").focus(),20); }
function renderSearch(){ const results=$("#search-results"); results.replaceChildren(); const found=searchObjects($("#search-input").value); if(!found.length){results.innerHTML='<div class="search-empty">No matching objects.</div>';return;} found.slice(0,12).forEach(object=>{const item=document.createElement("div");item.className="search-result";item.innerHTML="<strong></strong><small></small>";item.querySelector("strong").textContent=object.title;item.querySelector("small").textContent=`${label(object.type)} · ${object.content||"No content"}`;item.onclick=()=>{closeSearch();openEditor(object.id)};results.appendChild(item);}); }
function closeSearch(){ $("#search-modal").hidden=true; }
function exportWorkspace(){ const blob=new Blob([JSON.stringify({version:1,exportedAt:new Date().toISOString(),objects},null,2)],{type:"application/json"}); const link=document.createElement("a");link.href=URL.createObjectURL(blob);link.download="atlas-workspace.json";link.click();URL.revokeObjectURL(link.href); }
function importWorkspace(file){ const reader=new FileReader();reader.onload=()=>{try{const data=JSON.parse(reader.result);if(!Array.isArray(data.objects))throw new Error("Invalid workspace");objects=data.objects.filter(item=>item.title&&item.type);persist();render();}catch{alert("Import non valido: usa un export Atlas JSON.");}};reader.readAsText(file); }

$("#editor-form").addEventListener("submit",event=>{event.preventDefault();const data={type:$("#object-type").value,title:$("#object-title").value,content:$("#object-content").value,tags:$("#object-tags").value.split(",")};if(!data.title.trim())return;if(editingId)updateObject(editingId,data);else createObject(data);closeEditor();});
$("#quick-form").addEventListener("submit",event=>{event.preventDefault();const value=$("#quick-input").value.trim();if(value){createObject({title:value,type:"note",content:"",tags:["inbox"]});$("#quick-input").value="";}});
$$('[data-action="new"]').forEach(button=>button.addEventListener("click",()=>openEditor()));
$$('[data-action="search"]').forEach(button=>button.addEventListener("click",openSearch));
$$('[data-action="export"]').forEach(button=>button.addEventListener("click",exportWorkspace));
$$('[data-action="close-editor"]').forEach(button=>button.addEventListener("click",closeEditor));
$$('[data-action="close-search"]').forEach(button=>button.addEventListener("click",closeSearch));
$$('[data-view]').forEach(button=>button.addEventListener("click",()=>{$$('[data-view]').forEach(item=>item.classList.remove("active"));button.classList.add("active");activeView=button.dataset.view;render();}));
$("#search-input").addEventListener("input",renderSearch);
$("#import-input").addEventListener("change",event=>{if(event.target.files[0])importWorkspace(event.target.files[0]);event.target.value="";});
$("#filter-button").addEventListener("click",()=>{const types=["all","note","project","source","person","task"];activeType=types[(types.indexOf(activeType)+1)%types.length];$("#filter-button").textContent=activeType === "all" ? "All types ▾" : `${label(activeType)} ▾`;render();});
document.addEventListener("keydown",event=>{if((event.metaKey||event.ctrlKey)&&event.key.toLowerCase()==="k"){event.preventDefault();openSearch();}if(event.key==="Escape"){closeEditor();closeSearch();}});
render();
