/obj/effect/proc_holder/changeling/sting
	name = "Tiny Prick"
	desc = "Stabby stabby"
	var/sting_icon = null

/obj/effect/proc_holder/changeling/sting/Click()
	var/mob/user = usr
	if(!user || !user.mind || !user.mind.changeling)
		return
	if(!(user.mind.changeling.chosen_sting))
		set_sting(user)
	else
		unset_sting(user)
	return

/obj/effect/proc_holder/changeling/sting/proc/set_sting(mob/user)
	user << "<span class='notice'>We prepare our sting, use alt+click or middle mouse button on target to sting them.</span>"
	user.mind.changeling.chosen_sting = src
	user.hud_used.lingstingdisplay.icon_state = sting_icon
	user.hud_used.lingstingdisplay.invisibility = 0

/obj/effect/proc_holder/changeling/sting/proc/unset_sting(mob/user)
	user << "<span class='warning'>We retract our sting, we can't sting anyone for now.</span>"
	user.mind.changeling.chosen_sting = null
	user.hud_used.lingstingdisplay.icon_state = null
	user.hud_used.lingstingdisplay.invisibility = INVISIBILITY_ABSTRACT

/mob/living/carbon/proc/unset_sting()
	if(mind && mind.changeling && mind.changeling.chosen_sting)
		src.mind.changeling.chosen_sting.unset_sting(src)

/obj/effect/proc_holder/changeling/sting/can_sting(mob/user, mob/target)
	if(!..())
		return
	if(!user.mind.changeling.chosen_sting)
		user << "We haven't prepared our sting yet!"
	if(!iscarbon(target))
		return
	if(!isturf(user.loc))
		return
	if(!AStar(user, target.loc, /turf/proc/Distance, user.mind.changeling.sting_range, simulated_only = 0))
		return
	if(target.mind && target.mind.changeling)
		sting_feedback(user,target)
		take_chemical_cost(user.mind.changeling)
		return
	if(ishuman(user))
		var/mob/living/carbon/human/H = user //it only works with H for some reason
		if(isabomination(H))
			user << "<span class='warning'>We cannot do this whilst transformed. Revert first.</span>"
			return
	return 1

/obj/effect/proc_holder/changeling/sting/sting_feedback(mob/user, mob/target)
	if(!target)
		return
	user << "<span class='notice'>We stealthily sting [target.name].</span>"
	if(target.mind && target.mind.changeling)
		target << "<span class='warning'>You feel a tiny prick.</span>"
	return 1


/obj/effect/proc_holder/changeling/sting/transformation
	name = "Transformation Sting"
	desc = "We silently sting a human, injecting a retrovirus that forces them to transform."
	helptext = "The victim will transform much like a changeling would. The effects will be obvious to the victim."
	sting_icon = "sting_transform"
	chemical_cost = 30
	dna_cost = 1
	var/datum/changelingprofile/selected_dna = null

/obj/effect/proc_holder/changeling/sting/transformation/Click()
	var/mob/user = usr
	var/datum/changeling/changeling = user.mind.changeling
	if(changeling.chosen_sting)
		unset_sting(user)
		return
	selected_dna = changeling.select_dna("Select the target DNA: ", "Target DNA")
	if(!selected_dna)
		return
	if(NOTRANSSTING in selected_dna.dna.species.specflags)
		user << "<span class = 'notice'>That DNA is not compatible with changeling retrovirus!"
		return
	..()

/obj/effect/proc_holder/changeling/sting/transformation/can_sting(mob/user, mob/target)
	if(!..())
		return
	if((target.disabilities & HUSK) || !target.has_dna())
		user << "<span class='warning'>Our sting appears ineffective against its DNA.</span>"
		return 0
	return 1

/obj/effect/proc_holder/changeling/sting/transformation/sting_action(mob/user, mob/target)
	add_logs(user, target, "stung", "transformation sting", " new identity is [selected_dna.dna.real_name]")
	var/datum/dna/NewDNA = selected_dna.dna
	if(ismonkey(target))
		user << "<span class='notice'>Our genes cry out as we sting [target.name]!</span>"

	if(iscarbon(target))
		var/mob/living/carbon/C = target
		if(CANWEAKEN in C.status_flags)
			C.do_jitter_animation(500)
		target.visible_message("<span class='danger'>[target] begins to violenty convulse!</span>","<span class='userdanger'>You feel a tiny prick and a begin to uncontrollably convulse!</span>")
		spawn(10)
			C.real_name = NewDNA.real_name
			NewDNA.transfer_identity(C, transfer_SE=1)
			C.updateappearance(mutcolor_update=1)
			C.domutcheck()
	feedback_add_details("changeling_powers","TS")
	return 1


/obj/effect/proc_holder/changeling/sting/false_armblade
	name = "Armblade Sting"
	desc = "We silently sting a human, injecting a retrovirus that temporarily mutates their arm into an armblade."
	helptext = "The victim will form an armblade much like a changeling would. Beware, it is as deadly as one of ours!"
	sting_icon = "sting_armblade"
	chemical_cost = 10
	dna_cost = 1
	genetic_damage = 20
	max_genetic_damage = 10


/obj/effect/proc_holder/changeling/sting/false_armblade/can_sting(mob/user, mob/target)
	if(!..())
		return
	if((target.disabilities & HUSK) || !target.has_dna())
		user << "<span class='warning'>Our sting appears ineffective against its DNA. Perhaps we should try something with DNA.</span>"
		return 0
	return 1

/obj/effect/proc_holder/changeling/sting/false_armblade/sting_action(mob/user, mob/target)
	add_logs(user, target, "stung", object="armblade sting")

	if(!target.drop_item())
		user << "<span class='warning'>The [target.get_active_hand()] is stuck to their hand, you cannot grow an armblade over it!</span>"
		return

	if(ismonkey(target))
		user << "<span class='notice'>Our genes cry out as we sting [target.name]!</span>"

	var/obj/item/weapon/melee/arm_blade/blade = new(target,1)
	target.put_in_hands(blade)
	target.visible_message("<span class='warning'>A grotesque blade forms around [target.name]\'s arm!</span>", "<span class='userdanger'>Your arm twists and mutates, transforming into a horrific monstrosity!</span>", "<span class='italics'>You hear organic matter ripping and tearing!</span>")
	playsound(target, 'sound/effects/blobattack.ogg', 30, 1)

	addtimer(src, "remove_fake", rand(450, 800), FALSE, target, blade)

	feedback_add_details("changeling_powers","AS")
	return 1

/obj/effect/proc_holder/changeling/sting/false_armblade/proc/remove_fake(mob/target, obj/item/weapon/melee/arm_blade/blade)
	playsound(target, 'sound/effects/blobattack.ogg', 30, 1)
	target.visible_message("<span class='warning'>With a sickening crunch, \
	[target] reforms their [blade.name] into an arm!</span>",
	"<span class='warning'>[blade] reforms back to normal.</span>",
	"<span class='italics>You hear organic matter ripping and tearing!</span>")

	qdel(blade)
	target.update_inv_l_hand()
	target.update_inv_r_hand()

/obj/effect/proc_holder/changeling/sting/extract_dna
	name = "Extract DNA Sting"
	desc = "We stealthily sting a target and extract their DNA."
	helptext = "Will give you the DNA of your target, allowing you to transform into them."
	sting_icon = "sting_extract"
	chemical_cost = 25
	dna_cost = 0

/obj/effect/proc_holder/changeling/sting/extract_dna/can_sting(mob/user, mob/target)
	if(..())
		return user.mind.changeling.can_absorb_dna(user, target)

/obj/effect/proc_holder/changeling/sting/extract_dna/sting_action(mob/user, mob/living/carbon/human/target)
	add_logs(user, target, "stung", "extraction sting")
	if((user.mind.changeling.has_dna(target.dna)))
		user.mind.changeling.remove_profile(target)
		user.mind.changeling.profilecount--
		user << "<span class='notice'>We refresh our DNA information on [target]!</span>"
	var/protect = 0 //Should the system be prevented from automatically replacing this DNA?
	for(var/datum/objective/escape/escape_with_identity/ewi in user.mind.objectives)
		if(ewi.target == target.mind)
			protect = 1
			break
	user.mind.changeling.add_new_profile(target, user, protect)
	feedback_add_details("changeling_powers","ED")
	return 1

/obj/effect/proc_holder/changeling/sting/mute
	name = "Mute Sting"
	desc = "We silently sting a human, completely silencing them for a short time."
	helptext = "Does not provide a warning to the victim that they have been stung, until they try to speak and cannot."
	sting_icon = "sting_mute"
	chemical_cost = 20
	dna_cost = 2

/obj/effect/proc_holder/changeling/sting/mute/sting_action(mob/user, mob/living/carbon/target)
	add_logs(user, target, "stung", "mute sting")
	if(target.reagents)
		target.reagents.add_reagent("mutetoxin", 20)
	feedback_add_details("changeling_powers","MS")
	return 1

/obj/effect/proc_holder/changeling/sting/blind
	name = "Blind Sting"
	desc = "Temporarily blinds the target."
	helptext = "This sting completely blinds a target for a short time."
	sting_icon = "sting_blind"
	chemical_cost = 25
	dna_cost = 1

/obj/effect/proc_holder/changeling/sting/blind/sting_action(mob/user, mob/living/carbon/target)
	add_logs(user, target, "stung", "blind sting")
	target << "<span class='danger'>Your eyes burn horrifically!</span>"
	target.become_nearsighted()
	target.blind_eyes(20)
	target.blur_eyes(40)
	feedback_add_details("changeling_powers","BS")
	return 1

/obj/effect/proc_holder/changeling/sting/LSD
	name = "Hallucinogenic Sting"
	desc = "Causes terror in the target."
	helptext = "We evolve the ability to sting a target with a powerful hallucinogenic chemical. The target does not notice they have been stung, and the effect occurs very quickly."
	sting_icon = "sting_lsd"
	chemical_cost = 20
	dna_cost = 1

/obj/effect/proc_holder/changeling/sting/LSD/sting_action(mob/user, mob/living/carbon/target)
	add_logs(user, target, "stung", "LSD sting")
	if(target.reagents)
		target.reagents.add_reagent("mindbreaker", 30)
	feedback_add_details("changeling_powers","HS")
	return 1

/*
/obj/effect/proc_holder/changeling/sting/cryo
	name = "Cryogenic Sting"
	desc = "We silently sting a human with a cocktail of chemicals that freeze them."
	helptext = "Does not provide a warning to the victim, though they will likely realize they are suddenly freezing."
	sting_icon = "sting_cryo"
	chemical_cost = 15
	dna_cost = 2

/obj/effect/proc_holder/changeling/sting/cryo/sting_action(mob/user, mob/target)
	add_logs(user, target, "stung", "cryo sting")
	if(target.reagents)
		target.reagents.add_reagent("frostoil", 30)
	feedback_add_details("changeling_powers","CS")
	return 1
*/
