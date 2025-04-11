# MADz-GameJam-04-2025
 Gamedev.js game jam from 04/2025 - MADz team


 <h1>Project Architecture</h1>
 <b>://res</b>
 <ul>
   <li>Assets</li>
     <ul>
      <li>Music</li>
      <li>SFX</li>
      <li>VFX</li>
      <li>UI</li>
      <li>2D</li>
      <li>3D</li>
     </ul>
   <li>Scenes</li>
     <ul>
      <li>Levels</li>
      <li>Objects</li>
      <li>UI</li>
     </ul>
   <li>Scripts</li>
      <ul>
       <li>Global</li>
       <li>NodeScripts</li>
       <li>Resources</li>
       <li>Tools</li>
      </ul>
 </ul>
  
<h1>Naming conventions: </h1>
<h2>Scenes :</h2> 
<b>UI Element (Menu, HUD, Overlay,...)</b> - ui_button<br/>
<b>Level Scenes (or sub-levels)</b>  - map_interactible_level<br/>
<b>Objects</b>  - obj_interactible_object<br/>
<br/>

<h2>Scripts : </h2> 
prefix_snake_case<br/>
<b>Node script</b>  - scr_node_script<br/>
<b>Singleton/Autoload</b>  - glb_game_state<br/>
<b>Resource</b>  - res_resource<br/>
<b>Tool Script</b>  - tool_grid_snapping<br/>

<h2>Fonctions : </h2> 
snake_case<br/>
<b>Functions</b>  - func calculate_score -> Calculate something / Treat information / Do something<br/>
<b>Getters</b>  - func get_score -> Get a variable or a data<br/>
<b>Setters</b>  - func set_score -> Set a variable<br/>

<h2>Variables : </h2> 
<b>Local Variable</b>  - var current_health: float = 0f<br/>
<b>Exported Variabled</b>  - @export var ex_jump_force:float=0f<br/>
<b>Signals</b>  - signal sig_health_changed<br/>
<b>Constants</b>  - const MAX_LVL:float = 0f<br/>
