import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [ "statusConsole" ] // Make sure your status element is registered
  async connect() {
    // 1. Dynamic Code-Splitting: Only fetch the heavy library when this element physically enters the DOM
    // 1. Download the core package and assign it to the instance context
    const lib = await import("handsontable");
    this.Handsontable = lib.default;

    // 2. Safely capture the core base text renderer *before* configuring the grid
    this.baseTextRenderer = this.Handsontable.renderers.getRenderer('text');
    this.baseNumericRenderer = this.Handsontable.renderers.getRenderer('numeric');
    // 2. Build the configuration dictionary using our internal layouts
    const gridOptions = this.getGridConfiguration();

    // 3. Initialize the excel grid directly on this native node element
const gridContainer = this.element.querySelector('#grid1');
this.hot = new this.Handsontable(gridContainer, gridOptions);
//    this.hot = new this.Handsontable(this.element, gridOptions);
    window.hot = this.hot; // <--- This restores the 'hot' shortcut globally
    // 4. Trigger your custom legacy AJAX load event sequence
    this.loadDataFromServer();
  }

  getGridConfiguration() {
    const _this = this; 
    return {
      data: [[]], // Starts empty, populated later by AJAX
      height: 'auto',

      // 1. Define your Column Headers
      colHeaders: ['id','Time','Callsign','QRP', 'Port', 'Mode','Frq (MHz)','Snt RST','Rcd RST','Name','Description','Mnl?', 'codes', 'name', 'Id','loc','x','y'],
          afterGetColHeader(index, TH) {
            if (index === 11 && TH) {
              TH.children[0].title = 'I will specify parks manually - do not add automatically'
            }
          },
      columns: [
        {data: 'id', type: 'numeric',readOnly:true} , 
        {data: 'timetext', type: 'text', renderer: (instance, td, row, col, prop, value, cellProperties) => this.reqTextRenderer(instance, td, row, col, prop, value, cellProperties)},  
        {data: 'callsign2', type: 'text', renderer: (instance, td, row, col, prop, value, cellProperties) => this.reqTextRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'is_qrp2', type: 'checkbox'}, 
        {data: 'is_portable2', type: 'checkbox'}, 
        {data: 'mode', type: 'dropdown', source: ['SSB', 'CW', 'AM', 'FM', 'FT4', 'FT8', 'JS8', 'Data', 'Other']}, 
        {data: 'frequency', type: 'text', renderer: (instance, td, row, col, prop, value, cellProperties) => this.reqTextRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'signal2', type: 'numeric', renderer: (instance, td, row, col, prop, value, cellProperties) => this.reqValueRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'signal1', type: 'numeric', renderer: (instance, td, row, col, prop, value, cellProperties) => this.reqValueRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'name2', type: 'text', wordWrap: 'false', renderer: (instance, td, row, col, prop, value, cellProperties) => this.truncatedTextRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'loc_desc2', type: 'text', renderer: (instance, td, row, col, prop, value, cellProperties) => this.truncatedTextRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'do_not_lookup', type: 'checkbox'}, 
        {data: 'acton', renderer: _this.actionRenderer}, 
        {data: 'asset2_names', type: 'text',readOnly:true}, 
        {data: 'asset2_codes', readOnly:true, renderer: (instance, td, row, col, prop, value, cellProperties) => this.arrayRenderer(instance, td, row, col, prop, value, cellProperties)},
        {data: 'location2', type: 'numeric',readOnly:true} , 
        {data: 'x2', type: 'numeric',readOnly:true}, 
        {data: 'y2', type: 'numeric',readOnly:true} ], 
      manualColumnResize: [,,,40,40,,,50,50,50,150,,,,,,,],
      hiddenColumns: {
        columns: [0,14,15,16,17],
        indicators: false
      },
      startRows: 1,
      minSpareRows: 1,
      minSpareCols: 0,
      enterMoves: {row: 0, col: 1},
      maxCols: 24,
      licenseKey: 'non-commercial-and-evaluation',
      rowHeaders: false,
      afterChange: (change, source) => {
        if (source === 'loadData') {
          return; //don't save this change
        }
        document.getElementById('grid1console').innerText = 'Table has data that has not yet been saved';
        document.getElementById("submit_button").disabled = true
     
        if (!autosave.checked) {
          return;
        }
        clearTimeout(autosaveNotification);
        ajax('patch.json', 'POST', JSON.stringify({data: change}), function (data) {
          this.statusConsoleTarget.innerText  = 'Autosaved (' + change.length + ' ' + 'cell' + (change.length > 1 ? 's' : '') + ')';
          autosaveNotification = setTimeout(function() {
            this.statusConsoleTarget.innerText ='Changes will be autosaved';
          }, 1000);
        });
      }
    };
  }

  // Your clean data loader handler replacing inline view scripts
  async loadDataFromServer(event) {
    if (event) event.preventDefault();
    if (!this.hot) return;

    const logId = this.element.dataset.logId;
    const url = '/logs/'+logId+'/load.json'
    try {
      const response = await fetch(url);
      const serverData = await response.json();

      // Update Handsontable dynamically with the fresh server array
      if (this.hot && serverData) {
        this.hot.loadData(serverData);
      }
    } catch (error) {
      console.error("Handsontable background data load failed:", error);
    }
  }

  // === THE MODERN ASYNC SAVE CONTROLLER ACTION ===
  async saveTable(event) {
    if (event) event.preventDefault();
    if (!this.hot) return;

    const logId = this.element.dataset.logId;

    if (!logId) {
      console.error("Missing logId attribute configuration parameters on the container!");
      return;
    }
    // 1. Target your button and update statusConsole text cleanly
    const submitButton = document.getElementById("submit_button");
    this.statusConsoleTarget.innerText = 'Saving data...';

    // 2. Safely extract the modern Rails 8 CSRF Authenticity Token from the HTML head meta tags
    const csrfToken = document.querySelector('meta[name="csrf-token"]')?.getAttribute('content');

    // 3. Capture the entire active spreadsheet grid matrix array exactly as before
    const tablePayload = this.hot.getSourceData();

    try {
      // 4. Execute a modern, asynchronous fetch network post to your Rails 8 endpoint
      const response = await fetch(`/logs/${logId}/save.json`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-CSRF-Token': csrfToken // <-- CRITICAL SECURITY HEADER FOR RAILS 8!
        },
        body: JSON.stringify({ data: tablePayload })
      });

      if (!response.ok) throw new Error('Network save validation failed');

      // 5. Parse the returned clean database data array strings
      const freshServerData = await response.json();

      if (freshServerData && this.hot) {
        // Load the updated database rows (including newly assigned database IDs) back into the matrix cells
        this.hot.loadData(freshServerData);

        this.statusConsoleTarget.innerText = 'Data saved';
        if (submitButton) {
          submitButton.disabled = false;
        }
      }
    } catch (error) {
      console.error("Handsontable background commit failed:", error);
      this.statusConsoleTarget.innerText = 'Save error';
    }
  }
//  Handsontable.dom.addEvent(save, 'click', function() {
//    // save all cell's data
//    ajax('/logs/<%=@log.id.to_s%>/save.json', 'POST', JSON.stringify({data: hot.getData()}), function (res) {
//      data2 = JSON.parse(res.response);
//      result=hot.loadData(data2);
// 
//      if (!result) {
//        statusConsoleTarget.innerText = 'Data saved';
//        document.getElementById("submit_button").disabled = false
//      }
//      else {
//        statusConsoleTarget.innerText = 'Save error';
//      }
//     });
//  });
//
//  Handsontable.dom.addEvent(autosave, 'click', function() {
//    if (autosave.checked) {
//      statusConsoleTarget.innerText = 'Changes will be autosaved';
//    }
//    else {
//      statusConsoleTarget.innerText ='Changes will not be autosaved';
//    }
//  });
//  Handsontable.hooks.add('afterCreateRow',newRowCallback);

  reqTextRenderer(instance, td, row, col, prop, value, cellProperties) {
    this.baseTextRenderer(instance, td, row, col, prop, value, cellProperties);

    if (value === "" || value === null || value === undefined) {
    td.style.background = '#fcc';
    } else {
      td.style.background = ''; 
    }
  }

  truncatedTextRenderer(instance, td, row, col, prop, value, cellProperties) {
    this.baseTextRenderer(instance, td, row, col, prop, value, cellProperties);
          td.innerHTML = `<div class="truncated">${value||""}</div>`
  }
 
  arrayRenderer(instance, td, row, col, prop, value, cellProperties) {
    this.baseTextRenderer(instance, td, row, col, prop, value, cellProperties);
    if(value) { var stringval=value.join(',');} else {var stringval=[];}
    td.innerHTML = stringval;
  }

  reqValueRenderer(instance, td, row, col, prop, value, cellProperties) {
    this.baseNumericRenderer(instance, td, row, col, prop, value, cellProperties);
    var id=instance.getDataAtCell(row, 0);
    if (id>0) {
      if (!value || value == '') {
        td.style.background = '#fcc';
      } else {
        td.style.background = '';
      }
    }
  }

//        actionRenderer(instance, td, row, col, prop, value, cellProperties) {
//          var tzindex=7000-row*10;
//          var h1='<li><a href="#", onclick="search_assets(\'row_'+row+'\');return false;">... from list</a></li>';
//          var h2='<li><a href="#",  onclick="site_selectPlace('+row+',\'asset2_codes\',\'asset2_names\',\'location2\',\'x2\',\'y2\', null, null, site_green_star,true);return false;">.. from map</a></li>';
//          var h3='<li><a href="#",  onclick="site_clear_elementData('+row+',[\'asset2_codes\',\'asset2_names\',\'location2\' ]);map_clear_scratch_layer(null,site_green_star);return false;">Clear</a></li>';
//        
//          var $button = $('<div class="navbar ilnb" style="padding:0; margin:0;"><ul style="float: left;margin: 0;z-index:'+tzindex+'" class="nav pull-left" id="menus"> <li id="fat-menu" class="dropdown ildd" > <a href="#" class="dropdown-toggle" data-toggle="dropdown" > Add Place <b class="caret"></b> </a> <ul class="dropdown-menu ildd-menu"> '+h1+h2+h3+' </ul> </li> </ul></div>');
//          tzindex=tzindex-100;
//          $(td).empty().append($button); //empty is needed because you are rendering to an existing cell
//          td.style.overflow="visible";
//        };

	actionRenderer(instance, td, row, col, prop, value, cellProperties) {
  // 1. Always check if the row cell is valid or has active backing data first
  const rowData = instance.getSourceDataAtRow(row);
  if (!rowData) return td;

  // 2. Clear out any ghost cells from the recycling view engine
  td.innerHTML = '';

  // 3. Construct the clean Bootstrap 4 wrapper frame
  const wrapper = document.createElement('div');
  wrapper.className = 'dropdown position-static'; // Keeps menus un-clipped by the cell container
  wrapper.style.margin = '0';
  wrapper.style.padding = '0';

  const button = document.createElement('a');
  button.className = 'btn btn-sm btn-light dropdown-toggle py-0';
  button.href = '#';
  button.setAttribute('data-toggle', 'dropdown');
  button.innerHTML = 'Add Place <span class="caret"></span>';

  const menu = document.createElement('ul');
  menu.className = 'dropdown-menu dropdown-menu-left';
  menu.style.zIndex = '9999'; // Float cleanly over your maps and grids

  // --- ITEM 1: FROM LIST ---
  const li1 = document.createElement('li');
  const a1 = document.createElement('a');
  a1.href = '#';
  a1.className = 'dropdown-item small py-1';
  a1.innerText = '... from list';
  // Attach the listener directly — it can now read row metadata cleanly!
  a1.addEventListener('click', (e) => {
    e.preventDefault();
    if (window.search_assets) {
      window.search_assets(`row_${row}`);
    }
  });
  li1.appendChild(a1);

  // --- ITEM 2: FROM MAP ---
  const li2 = document.createElement('li');
  const a2 = document.createElement('a');
  a2.href = '#';
  a2.className = 'dropdown-item small py-1';
  a2.innerText = '.. from map';
  a2.addEventListener('click', (e) => {
    e.preventDefault();
    if (window.site_selectPlace) {
      window.site_selectPlace(row, 'asset2_codes', 'asset2_names', 'location2', 'x2', 'y2', null, null, window.site_green_star, true);
    }
  });
  li2.appendChild(a2);

  // --- ITEM 3: CLEAR ---
  const li3 = document.createElement('li');
  const a3 = document.createElement('a');
  a3.href = '#';
  a3.className = 'dropdown-item small py-1 text-danger';
  a3.innerText = 'Clear';
  a3.addEventListener('click', (e) => {
    e.preventDefault();
    if (window.site_clear_elementData) {
      site_clear_elementData(row, ['loc_desc2', 'asset2_codes', 'asset2_names', 'location2']);
    }
    if (window.map_clear_scratch_layer) {
      window.map_clear_scratch_layer(null, window.site_green_star);
    }
  });
  li3.appendChild(a3);

  // 4. Assemble the elements into the cell view layer
  menu.appendChild(li1);
  menu.appendChild(li2);
  menu.appendChild(li3);

  wrapper.appendChild(button);
  wrapper.appendChild(menu);

  td.appendChild(wrapper);

  // 5. Enforce full overflow tracking boundaries on this specific cell container block
  td.style.overflow = 'visible';

  return td;
}


 newRowCallback() {
    newrow=data2.length-2;
    lastrow=newrow-1;
    if(lastrow>=0) {
      if(!data2[newrow]['mode']) {data2[newrow]['mode']=data2[lastrow]['mode']};
      if(!data2[newrow]['frequency']) {data2[newrow]['frequency']=data2[lastrow]['frequency']};
      if(!data2[newrow]['time']) {data2[newrow]['time']=data2[lastrow]['time']};
    };
    hot.render();

 }

 disconnect() {
    // 4. Memory Safeguard: Destroy the sheet instance if the user navigates away or clears the partial
    if (this.hot) {
      this.hot.destroy();
   }
  }



}

