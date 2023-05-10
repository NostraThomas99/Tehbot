Ok, so this version of Tehbot exists so that one might run Abyssals. 
Pre-Reqs - Really should be doing this in a Gila. Please, just use a Gila. Start at tier 1/2 then move up to 3/4. Runs tier 3s great.

Abyssal Runner Mode - The UI is jank as hell but self explanatory. This mainmode is what you want to be using.
MINIMODES - Along with the usual Tehbot minimodes, we have a few extras, and some changes to existing ones.

TargetManager - This minimode will basically shoot at any (NPC) target it feels like shooting at. I have removed most (if not all) targets that will probably get you in trouble. It won't shoot customs ships, or Concord, or EDENCOM (anymore). Otherwise it will just operate the weapons and shoot whatever it thinks is in range. You want this minimode on for the Abyss

RemoteRepManager - This minimode will, after some configuring in its UI, look at the type of remote reps you have available, and attempt to use them on fleet members who need them. Thresholdes are set in the UI. Has some minor code to keep it nearish to whoever is set as "The Leader". This isn't needed for abyssals, but it is something I bothered to make and it is fun. I don't make any guarantees about this minimode, it will probably behave at least a little oddly. It does, however, keep things that need reps, repped.

Drone Control - This is not a new minimode, but you do need this if you want to run Abyssals (in a Gila [USE A GILA]). I have modified this a bit so Gilas and Rattlesnakes (with their 2 drones) won't piss off the bot. Made a few other changes.

Automodule - Also not a new minimode, you absolutely need this though. If you plan on doing lots of abyssals, consider making it so your fit can handle running its rep all the time (and setting that option in this minimode).

Autothrust - No changes here, but you probably want to use a speed module (afterburner, mwd) so you should be using this. Don't forget to configure it or it won't actually do anything.

The UI for the abyssal mainmode is all kinds of weird because I'm bad at LavishUI. We have buttons for a few things. They are labeled. Some buttons don't update the UI unless you close that config window and open it again.
I've done everything in my power to ensure that the bot can handle being started at ANY GIVEN PART in an abyssal run. From in station to in the abyss and back again. An edge case remains where if you happen to start the bot between looting a wreck and going through a conduit it will sit and do nothing. I will fix that eventually, just go through the conduit yourself and it will resume.
The bot will pick up a (defensive) drug to use in the abyss if your tank starts to fall apart. Pick either Hardshell or Synth Blue Pill. It could save your life!
Configure whether it will be using your personal hangar or a corp hangar. If you don't do this the bot will just sit there, forever.
Configure your filament site, and your home base. Literally just type in the names of the two bookmarks exactly in the boxes.
Configure how much ammunition you will carry. Pro tip, carry enough for more runs than you are intending to run between returns to station. A return to station will be triggered if you drop below 40% of that initial amount.
Configure what drone you will use. No second set of drones here.
For the moment, using an MTU is a bad idea. It doesn't gain you much, and the bot will almost certainly grab the MTU and leave the cargo behind. The Nodes/Subnodes an MTU enables you to pick up are awful anyways. Please don't use this configuration until I've pieced together how to make it work correctly.
Configure your primary and secondary ammunition. One is short range, one is long. Do not use Xtra Long configuration, that is so far only configured for a Stormbringer, which I haven't gotten working perfectly yet.
The Overheat Weapons configuration also only applies to the Stormbringer for now.
A return to station will be triggered if you have any structure damage, or your first weapon slot has more than 50% or so heat damage.
A return to station will be triggered if you are missing drones. For a Gila that happens at 3 drones being missing. For smaller ships it scales down. Did I mention that you should be using a Gila.
A return to station will be triggered if you have used up all your available Filaments. The bot will go through more runs if you happen to keep picking up more of the filament you are using while it is running.
A return to station will be triggered if you have used up your drugs (unlikely).
A return to station will be triggered if you are configured to use an MTU and have lost it (don't do it, don't use an MTU yet).

Important sidenote. If you are not going to use a gila (its a really stupid idea to not use a gila) ensure that your ship can hit out to the approximate edge of the safe zone keeping in mind that some of these abyssal rats rather enjoy their EWAR.
Functionality for approaching things outside your range is not implemented except for the case of those battleships that hug the edge of the safe zone. Keep your 10km rocket fits at home.

As always, let me know in the Discord if things don't behave correctly.

_______________________________________________________________________________________________________________________________________________________________________________________________________________________________________________________

I am now working on bringing mining to this fork. As of May 10th it is incomplete.
