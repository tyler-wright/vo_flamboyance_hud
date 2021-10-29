# FlamboyanceHUD - Dynamic HUD Colour Generation for Vendetta Online

FlamboyanceHUD is a plugin to dynamically change the colour of HUD elements
based on conditions, events or custom preferences. It has featured in a number
of videos for Vendetta Online.

The plugin is based on an RGB palette system which allows you to define any RGB
colour and apply it to the IUP elements that Vendetta Online uses for its ship
HUD interface.

The following modes exist:

- `/hud R G B` [`new`] - Will generate a palette based on the colour RGB value you feed into it, 3 numbers between 0-255.

- `/hud ship` [`new`] - Will set your hud to the colour of your ship. Light coloured ships work better with this mode.

- `/hud health` [`new`] - Will set your hud to a light green and gets progressively yellower and then redder as you lose health. Makes the whole HUD function like a health indicator.

- `/hud random` [`new`] - Will set your hud to a random colour palette every time you undock.

- `/hud fresh` [`new`] - Will set your hud to a random colour palette and saves it permanently.

- `/hud factionspace` [`new`] - Will set your hud based on the alignment of the sector you are in.

Adding "new" to the end of the command will replace the recticles with the new high-contrast ones.
