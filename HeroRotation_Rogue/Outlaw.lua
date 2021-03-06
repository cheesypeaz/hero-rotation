--- Localize Vars
-- Addon
local addonName, addonTable = ...;
-- HeroLib
local HL = HeroLib;
local Cache = HeroCache;
local Unit = HL.Unit;
local Player = Unit.Player;
local Target = Unit.Target;
local Spell = HL.Spell;
local Item = HL.Item;
-- HeroRotation
local HR = HeroRotation;
-- Lua
local pairs = pairs;
local tableconcat = table.concat;
local tostring = tostring;


--- APL Local Vars
-- Commons
local Everyone = HR.Commons.Everyone;
local Rogue = HR.Commons.Rogue;

-- Spells
if not Spell.Rogue then Spell.Rogue = {}; end
Spell.Rogue.Outlaw = {
  -- Racials
  AncestralCall                   = Spell(274738),
  ArcanePulse                     = Spell(260364),
  ArcaneTorrent                   = Spell(25046),
  Berserking                      = Spell(26297),
  BloodFury                       = Spell(20572),
  Fireblood                       = Spell(265221),
  LightsJudgment                  = Spell(255647),
  Shadowmeld                      = Spell(58984),
  -- Abilities
  AdrenalineRush                  = Spell(13750),
  Ambush                          = Spell(8676),
  BetweentheEyes                  = Spell(199804),
  BladeFlurry                     = Spell(13877),
  Opportunity                     = Spell(195627),
  PistolShot                      = Spell(185763),
  RolltheBones                    = Spell(193316),
  Dispatch                        = Spell(2098),
  SinisterStrike                  = Spell(193315),
  Stealth                         = Spell(1784),
  Vanish                          = Spell(1856),
  VanishBuff                      = Spell(11327),
  -- Talents
  AcrobaticStrikes                = Spell(196924),
  BladeRush                       = Spell(271877),
  DeeperStratagem                 = Spell(193531),
  GhostlyStrike                   = Spell(196937),
  KillingSpree                    = Spell(51690),
  LoadedDiceBuff                  = Spell(256171),
  MarkedforDeath                  = Spell(137619),
  QuickDraw                       = Spell(196938),
  SliceandDice                    = Spell(5171),
  -- Azerite Traits
  AceUpYourSleeve                 = Spell(278676),
  Deadshot                        = Spell(272935),
  SnakeEyesPower                  = Spell(275846),
  SnakeEyesBuff                   = Spell(275863),
  -- Defensive
  CrimsonVial                     = Spell(185311),
  Feint                           = Spell(1966),
  -- Utility
  Kick                            = Spell(1766),
  -- Roll the Bones
  Broadside                       = Spell(193356),
  BuriedTreasure                  = Spell(199600),
  GrandMelee                      = Spell(193358),
  RuthlessPrecision               = Spell(193357),
  SkullandCrossbones              = Spell(199603),
  TrueBearing                     = Spell(193359)
};
local S = Spell.Rogue.Outlaw;

-- Items
if not Item.Rogue then Item.Rogue = {}; end
Item.Rogue.Outlaw = {
};
local I = Item.Rogue.Outlaw;

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local BladeFlurryRange = 6;

-- GUI Settings
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Rogue.Commons,
  Outlaw = HR.GUISettings.APL.Rogue.Outlaw
};

local function num(val)
  if val then return 1 else return 0 end
end

-- APL Action Lists (and Variables)
local SappedSoulSpells = {
  {S.Kick, "Cast Kick (Sapped Soul)", function () return Target:IsInRange(S.SinisterStrike); end},
  {S.Feint, "Cast Feint (Sapped Soul)", function () return true; end},
  {S.CrimsonVial, "Cast Crimson Vial (Sapped Soul)", function () return true; end}
};
local RtB_BuffsList = {
  S.Broadside,
  S.BuriedTreasure,
  S.GrandMelee,
  S.RuthlessPrecision,
  S.SkullandCrossbones,
  S.TrueBearing
};
local function RtB_List (Type, List)
  if not Cache.APLVar.RtB_List then Cache.APLVar.RtB_List = {}; end
  if not Cache.APLVar.RtB_List[Type] then Cache.APLVar.RtB_List[Type] = {}; end
  local Sequence = table.concat(List);
  -- All
  if Type == "All" then
    if not Cache.APLVar.RtB_List[Type][Sequence] then
      local Count = 0;
      for i = 1, #List do
        if Player:Buff(RtB_BuffsList[List[i]]) then
          Count = Count + 1;
        end
      end
      Cache.APLVar.RtB_List[Type][Sequence] = Count == #List and true or false;
    end
  -- Any
  else
    if not Cache.APLVar.RtB_List[Type][Sequence] then
      Cache.APLVar.RtB_List[Type][Sequence] = false;
      for i = 1, #List do
        if Player:Buff(RtB_BuffsList[List[i]]) then
          Cache.APLVar.RtB_List[Type][Sequence] = true;
          break;
        end
      end
    end
  end
  return Cache.APLVar.RtB_List[Type][Sequence];
end
local function RtB_BuffRemains ()
  if not Cache.APLVar.RtB_BuffRemains then
    Cache.APLVar.RtB_BuffRemains = 0;
    for i = 1, #RtB_BuffsList do
      if Player:Buff(RtB_BuffsList[i]) then
        Cache.APLVar.RtB_BuffRemains = Player:BuffRemainsP(RtB_BuffsList[i]);
        break;
      end
    end
  end
  return Cache.APLVar.RtB_BuffRemains;
end
-- Get the number of Roll the Bones buffs currently on
local function RtB_Buffs ()
  if not Cache.APLVar.RtB_Buffs then
    Cache.APLVar.RtB_Buffs = 0;
    for i = 1, #RtB_BuffsList do
      if Player:BuffP(RtB_BuffsList[i]) then
        Cache.APLVar.RtB_Buffs = Cache.APLVar.RtB_Buffs + 1;
      end
    end
  end
  return Cache.APLVar.RtB_Buffs;
end
-- RtB rerolling strategy, return true if we should reroll
local function RtB_Reroll ()
  if not Cache.APLVar.RtB_Reroll then
    -- Defensive Override : Grand Melee if HP < 60
    if Settings.General.SoloMode and Player:HealthPercentage() < Settings.Outlaw.RolltheBonesLeechHP then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.GrandMelee)) and true or false;
    -- 1+ Buff
    elseif Settings.Outlaw.RolltheBonesLogic == "1+ Buff" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and RtB_Buffs() <= 0) and true or false;
    -- Broadside
    elseif Settings.Outlaw.RolltheBonesLogic == "Broadside" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.Broadside)) and true or false;
    -- Buried Treasure
    elseif Settings.Outlaw.RolltheBonesLogic == "Buried Treasure" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.BuriedTreasure)) and true or false;
    -- Grand Melee
    elseif Settings.Outlaw.RolltheBonesLogic == "Grand Melee" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.GrandMelee)) and true or false;
    -- Jolly Roger
    elseif Settings.Outlaw.RolltheBonesLogic == "Jolly Roger" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.JollyRoger)) and true or false;
    -- Shark Infested Waters
    elseif Settings.Outlaw.RolltheBonesLogic == "Shark Infested Waters" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.SharkInfestedWaters)) and true or false;
    -- True Bearing
    elseif Settings.Outlaw.RolltheBonesLogic == "True Bearing" then
      Cache.APLVar.RtB_Reroll = (not S.SliceandDice:IsAvailable() and not Player:BuffP(S.TrueBearing)) and true or false;
    -- SimC Default
    else
      -- # Reroll for 2+ buffs with Loaded Dice up. Otherwise reroll for 2+ or Grand Melee or Ruthless Precision.
      -- actions=variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
      -- # Reroll for 2+ buffs or Ruthless Precision with Deadshot Rank 2+.
      -- actions+=/variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
      -- # Always reroll for 2+ buffs with Snake Eyes unless at 3 Ranks, then reroll everything.
      -- actions+=/variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.enabled,value=rtb_buffs<2|(azerite.snake_eyes.rank=3&rtb_buffs<5)
      if S.SnakeEyesPower:AzeriteEnabled() then
        if S.SnakeEyesPower:AzeriteRank() == 3 then
          Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 5) and true or false;
        else
          Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2) and true or false;
        end
        -- # Do not reroll if Snake Eyes is at 2+ Ranks and 2+ stacks of the buff (1+ stack with Broadside up)
        -- actions+=/variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
        if S.SnakeEyesPower:AzeriteRank() >= 2 and Player:BuffStackP(S.SnakeEyesBuff) >= 2 - num(Player:BuffP(S.Broadside)) then
          Cache.APLVar.RtB_Reroll = false;
        end
      elseif S.Deadshot:AzeriteEnabled() or S.AceUpYourSleeve:AzeriteEnabled() then
        Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2 and (Player:BuffP(S.LoadedDiceBuff) or
          Player:BuffRemainsP(S.RuthlessPrecision) <= S.BetweentheEyes:CooldownRemainsP())) and true or false;
      else
        Cache.APLVar.RtB_Reroll = (RtB_Buffs() < 2 and (Player:BuffP(S.LoadedDiceBuff) or
          (not Player:BuffP(S.GrandMelee) and not Player:BuffP(S.RuthlessPrecision)))) and true or false;
      end
    end
  end
  return Cache.APLVar.RtB_Reroll;
end
-- # Condition to use Stealth cooldowns for Ambush
local function Ambush_Condition ()
  -- actions+=/variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
  return Player:ComboPointsDeficit() >= 2 + 2 * ((S.GhostlyStrike:IsAvailable() and S.GhostlyStrike:CooldownRemainsP() < 1) and 1 or 0)
    + (Player:Buff(S.Broadside) and 1 or 0) and Player:EnergyPredicted() > 60 and not Player:Buff(S.SkullandCrossbones);
end
-- # With multiple targets, this variable is checked to decide whether some CDs should be synced with Blade Flurry
-- actions+=/variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
local function Blade_Flurry_Sync ()
  return not HR.AoEON() or Cache.EnemiesCount[BladeFlurryRange] < 2 or Player:BuffP(S.BladeFlurry)
end

local function EnergyTimeToMaxRounded ()
  -- Round to the nearesth 10th to reduce prediction instability on very high regen rates
  return math.floor(Player:EnergyTimeToMaxPredicted() * 10 + 0.5) / 10;
end

local function MythicDungeon ()
  -- Sapped Soul
  if HL.MythicDungeon() == "Sapped Soul" then
    for i = 1, #SappedSoulSpells do
      if SappedSoulSpells[i][1]:IsCastable() and SappedSoulSpells[i][3]() then
        HR.ChangePulseTimer(1);
        HR.Cast(SappedSoulSpells[i][1]);
        return SappedSoulSpells[i][2];
      end
    end
  end
end

local function TrainingScenario ()
  if Target:CastName() == "Unstable Explosion" and Target:CastPercentage() > 60-10*Player:ComboPoints() then
    -- Between the Eyes
    if S.BetweentheEyes:IsCastable(20) and Player:ComboPoints() > 0 then
      if HR.Cast(S.BetweentheEyes) then return "Cast Between the Eyes (Training Scenario)"; end
    end
  end
end

local function CDs ()
  -- actions.cds=potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
  -- TODO: Add Potion
  -- actions.cds+=/use_item,if=buff.bloodlust.react|target.time_to_die<=20|combo_points.deficit<=2
  -- TODO: Add Items
  if Target:IsInRange(S.SinisterStrike) then
    if HR.CDsON() then
      -- actions.cds+=/blood_fury
      if S.BloodFury:IsCastable() then
        if HR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Blood Fury"; end
      end
      -- actions.cds+=/berserking
      if S.Berserking:IsCastable() then
        if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Berserking"; end
      end
      -- actions.cds+=/fireblood
      if S.Fireblood:IsCastable() then
        if HR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Fireblood"; end
      end
      -- actions.cds+=/ancestral_call
      if S.AncestralCall:IsCastable() then
        if HR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Ancestral Call"; end
      end
      -- actions.cds+=/adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
      if S.AdrenalineRush:IsCastable() and not Player:BuffP(S.AdrenalineRush) and EnergyTimeToMaxRounded() > 1 then
        if HR.Cast(S.AdrenalineRush, Settings.Outlaw.GCDasOffGCD.AdrenalineRush) then return "Cast Adrenaline Rush"; end
      end
    end
    -- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=target.time_to_die<combo_points.deficit|((raid_event.adds.in>40|buff.true_bearing.remains>15-buff.adrenaline_rush.up*5)&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
    if S.MarkedforDeath:IsCastable() then
      -- Note: Increased the SimC condition by 50% since we are slower.
      if Target:FilteredTimeToDie("<", Player:ComboPointsDeficit()*1.5) or (Target:FilteredTimeToDie("<", 2) and Player:ComboPointsDeficit() > 0)
        or (((Player:BuffRemainsP(S.TrueBearing) > 15 - (Player:BuffP(S.AdrenalineRush) and 5 or 0)) or Target:IsDummy())
          and not Player:IsStealthedP(true, true) and Player:ComboPointsDeficit() >= Rogue.CPMaxSpend() - 1) then
        if HR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death"; end
      elseif not Player:IsStealthedP(true, true) and Player:ComboPointsDeficit() >= Rogue.CPMaxSpend() - 1 then
        HR.CastSuggested(S.MarkedforDeath);
      end
    end
    if HR.CDsON() then
      -- actions.cds+=/blade_flurry,if=spell_targets.blade_flurry>=2&!buff.blade_flurry.up
      if HR.AoEON() and S.BladeFlurry:IsCastable() and Cache.EnemiesCount[BladeFlurryRange] >= 2 and not Player:BuffP(S.BladeFlurry) then
        if Settings.Outlaw.GCDasOffGCD.BladeFlurry then
          HR.CastSuggested(S.BladeFlurry);
        else
          if HR.Cast(S.BladeFlurry) then return "Cast Blade Flurry"; end
        end
      end
      -- actions.cds+=/ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
      if S.GhostlyStrike:IsCastable(S.SinisterStrike) and Blade_Flurry_Sync() and Player:ComboPointsDeficit() >= (1 + (Player:BuffP(S.Broadside) and 1 or 0)) then
        if HR.Cast(S.GhostlyStrike) then return "Cast Ghostly Strike"; end
      end
      -- actions.cds+=/killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
      if S.KillingSpree:IsCastable(10) and Blade_Flurry_Sync() and (EnergyTimeToMaxRounded() > 5 or Player:EnergyPredicted() < 15) then
        if HR.Cast(S.KillingSpree, Settings.Outlaw.GCDasOffGCD.KillingSpree) then return "Cast Killing Spree"; end
      end
      -- actions.cds+=/blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
      if S.BladeRush:IsCastable(S.SinisterStrike) and Blade_Flurry_Sync() and EnergyTimeToMaxRounded() > 1 then
        if HR.Cast(S.BladeRush, Settings.Outlaw.GCDasOffGCD.BladeRush) then return "Cast Blade Rush"; end
      end
      if Settings.Outlaw.UseDPSVanish and not Player:IsStealthedP(true, true) then
        -- # Using Vanish/Ambush is only a very tiny increase, so in reality, you're absolutely fine to use it as a utility spell.
        -- actions.cds+=/vanish,if=!stealthed.all&variable.ambush_condition
        if S.Vanish:IsCastable() and Ambush_Condition() then
          if HR.Cast(S.Vanish, Settings.Commons.OffGCDasOffGCD.Vanish) then return "Cast Vanish"; end
        end
        -- actions.cds+=/shadowmeld,if=!stealthed.all&variable.ambush_condition
        if S.Shadowmeld:IsCastable() and Ambush_Condition() then
          if HR.Cast(S.Shadowmeld, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Shadowmeld"; end
        end
      end
    end
  end
end

local function Stealth ()
  if Target:IsInRange(S.SinisterStrike) then
    -- actions.stealth=ambush
    if S.Ambush:IsCastable() then
      if HR.Cast(S.Ambush) then return "Cast Ambush"; end
    end
  end
end

local function Finish ()
  -- # BtE over RtB rerolls with 2+ Deadshot traits or Ruthless Precision.
  -- actions.finish=between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
  if S.BetweentheEyes:IsCastable(20) and (Player:BuffP(S.RuthlessPrecision) or (S.Deadshot:AzeriteEnabled() or S.AceUpYourSleeve:AzeriteEnabled()) and RtB_Buffs() >= 1) then
    if HR.Cast(S.BetweentheEyes) then return "Cast Between the Eyes (Pre RtB)"; end
  end
  -- actions.finish=slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
  -- Note: Added Player:BuffRemainsP(S.SliceandDice) == 0 to maintain the buff while TTD is invalid (it's mainly for Solo, not an issue in raids)
  if S.SliceandDice:IsAvailable() and S.SliceandDice:IsCastable()
    and (Target:FilteredTimeToDie(">", Player:BuffRemainsP(S.SliceandDice)) or Target:TimeToDieIsNotValid() or Player:BuffRemainsP(S.SliceandDice) == 0)
    and Player:BuffRemainsP(S.SliceandDice) < (1 + Player:ComboPoints()) * 1.8 then
    if HR.Cast(S.SliceandDice) then return "Cast Slice and Dice"; end
  end
  -- actions.finish+=/roll_the_bones,if=(buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
  -- Note: Added RtB_BuffRemains() == 0 to maintain the buff while TTD is invalid (it's mainly for Solo, not an issue in raids)
  if S.RolltheBones:IsCastable() and (RtB_BuffRemains() <= 3 or RtB_Reroll())
    and (Target:FilteredTimeToDie(">", 20)
    or Target:FilteredTimeToDie(">", RtB_BuffRemains()) or Target:TimeToDieIsNotValid() or RtB_BuffRemains() == 0) then
    if HR.Cast(S.RolltheBones) then return "Cast Roll the Bones"; end
  end
  -- # BtE with the Ace Up Your Sleeve or Deadshot traits.
  -- actions.finish+=/between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
  if S.BetweentheEyes:IsCastable(20) and (S.AceUpYourSleeve:AzeriteEnabled() or S.Deadshot:AzeriteEnabled()) then
    if HR.Cast(S.BetweentheEyes) then return "Cast Between the Eyes"; end
  end
  -- actions.finish+=/dispatch
  if S.Dispatch:IsCastable(S.Dispatch) then
    if HR.Cast(S.Dispatch) then return "Cast Dispatch"; end
  end
  -- OutofRange BtE
  if S.BetweentheEyes:IsCastable(20) and not Target:IsInRange(10) then
    if HR.Cast(S.BetweentheEyes) then return "Cast Between the Eyes (OOR)"; end
  end
end

local function Build ()
  -- actions.build=pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
  if S.PistolShot:IsCastable(20)
    and Player:ComboPointsDeficit() >= (1 + (Player:BuffP(S.Broadside) and 1 or 0) + (S.QuickDraw:IsAvailable() and 1 or 0))
    and Player:BuffP(S.Opportunity) then
    if HR.Cast(S.PistolShot) then return "Cast Pistol Shot"; end
  end
  -- actions.build+=/sinister_strike
  if S.SinisterStrike:IsCastable(S.SinisterStrike) then
    if HR.Cast(S.SinisterStrike) then return "Cast Sinister Strike"; end
  end
end

-- APL Main
local function APL ()
  -- Unit Update
  BladeFlurryRange = S.AcrobaticStrikes:IsAvailable() and 9 or 6;
  HL.GetEnemies(BladeFlurryRange);
  HL.GetEnemies("Melee");

  -- Defensives
  -- Crimson Vial
  ShouldReturn = Rogue.CrimsonVial(S.CrimsonVial);
  if ShouldReturn then return ShouldReturn; end
  -- Feint
  ShouldReturn = Rogue.Feint(S.Feint);
  if ShouldReturn then return ShouldReturn; end

  -- Out of Combat
  if not Player:AffectingCombat() then
    -- Precombat CDs
    if HR.CDsON() then
      if S.MarkedforDeath:IsCastableP() and Player:ComboPointsDeficit() >= Rogue.CPMaxSpend() then
        if HR.Cast(S.MarkedforDeath, Settings.Commons.OffGCDasOffGCD.MarkedforDeath) then return "Cast Marked for Death (OOC)"; end
      end
      if Settings.Outlaw.PrecombatAR and Everyone.TargetIsValid() then
        if S.AdrenalineRush:IsCastable() and not Player:BuffP(S.AdrenalineRush) then
          if HR.Cast(S.AdrenalineRush, Settings.Outlaw.GCDasOffGCD.AdrenalineRush) then return "Cast Adrenaline Rush (OOC)"; end
        end
      end
    end
    -- Stealth
    if not Player:Buff(S.VanishBuff) then
      ShouldReturn = Rogue.Stealth(S.Stealth);
      if ShouldReturn then return ShouldReturn; end
    end
    -- Flask
    -- Food
    -- Rune
    -- PrePot w/ Bossmod Countdown
    -- Opener
    if Everyone.TargetIsValid() then
      if Player:ComboPoints() >= 5 then
        ShouldReturn = Finish();
        if ShouldReturn then return "Finish: " .. ShouldReturn; end
      elseif Target:IsInRange(S.SinisterStrike) then
        if Player:IsStealthedP(true, true) and S.Ambush:IsCastable() then
          if HR.Cast(S.Ambush) then return "Cast Ambush (Opener)"; end
        elseif S.SinisterStrike:IsCastable() then
          if HR.Cast(S.SinisterStrike) then return "Cast Sinister Strike (Opener)"; end
        end
      end
    end
    return;
  end

  -- In Combat
  -- MfD Sniping
  Rogue.MfDSniping(S.MarkedforDeath);
  if Everyone.TargetIsValid() then
    -- Mythic Dungeon
    ShouldReturn = MythicDungeon();
    if ShouldReturn then return ShouldReturn; end
    -- Training Scenario
    ShouldReturn = TrainingScenario();
    if ShouldReturn then return ShouldReturn; end
    -- Kick
    if Settings.General.InterruptEnabled and S.Kick:IsCastable(S.SinisterStrike) and Target:IsInterruptible() then
      if HR.Cast(S.Kick, Settings.Commons.OffGCDasOffGCD.Kick) then return "Cast Kick"; end
    end

    -- actions+=/call_action_list,name=stealth,if=stealthed.all
    if Player:IsStealthedP(true, true) then
      ShouldReturn = Stealth();
      if ShouldReturn then return "Stealth: " .. ShouldReturn; end
    end
    -- actions+=/call_action_list,name=cds
    ShouldReturn = CDs();
    if ShouldReturn then return "CDs: " .. ShouldReturn; end
    -- actions+=/call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
    if Player:ComboPoints() >= Rogue.CPMaxSpend() - (num(Player:BuffP(S.Broadside)) + num(Player:BuffP(S.Opportunity))) * num(S.QuickDraw:IsAvailable() and (not S.MarkedforDeath:IsAvailable() or S.MarkedforDeath:CooldownRemainsP() > 1)) then
      ShouldReturn = Finish();
      if ShouldReturn then return "Finish: " .. ShouldReturn; end
    end
    -- actions+=/call_action_list,name=build
    ShouldReturn = Build();
    if ShouldReturn then return "Build: " .. ShouldReturn; end
    -- actions+=/arcane_torrent,if=energy.deficit>=15+energy.regen
    if S.ArcaneTorrent:IsCastableP(S.SinisterStrike) and Player:EnergyDeficitPredicted() > 15 + Player:EnergyRegen() then
      if HR.Cast(S.ArcaneTorrent, Settings.Commons.OffGCDasOffGCD.Racials) then return "Cast Arcane Torrent"; end
    end
    -- actions+=/arcane_pulse
    if S.ArcanePulse:IsCastableP(S.SinisterStrike) then
      if HR.Cast(S.ArcanePulse) then return "Cast Arcane Pulse"; end
    end
    -- actions+=/lights_judgment
    if S.LightsJudgment:IsCastableP(S.SinisterStrike) then
      if HR.Cast(S.LightsJudgment, Settings.Commons.GCDasOffGCD.Racials) then return "Cast Lights Judgment"; end
    end
    -- OutofRange Pistol Shot
    if not Target:IsInRange(10) and S.PistolShot:IsCastable(20) and not Player:IsStealthedP(true, true)
      and Player:EnergyDeficitPredicted() < 25 and (Player:ComboPointsDeficit() >= 1 or EnergyTimeToMaxRounded() <= 1.2) then
      if HR.Cast(S.PistolShot) then return "Cast Pistol Shot (OOR)"; end
    end
  end
end

HR.SetAPL(260, APL);

-- Last Update: 2018-09-07

-- # Executed before combat begins. Accepts non-harmful actions only.
-- actions.precombat=flask
-- actions.precombat+=/augmentation
-- actions.precombat+=/food
-- # Snapshot raid buffed stats before combat begins and pre-potting is done.
-- actions.precombat+=/snapshot_stats
-- actions.precombat+=/stealth
-- actions.precombat+=/potion
-- actions.precombat+=/marked_for_death,precombat_seconds=5,if=raid_event.adds.in>40
-- actions.precombat+=/roll_the_bones,precombat_seconds=2
-- actions.precombat+=/slice_and_dice,precombat_seconds=2
-- actions.precombat+=/adrenaline_rush,precombat_seconds=1

-- # Executed every time the actor is available.
-- # Reroll for 2+ buffs with Loaded Dice up. Otherwise reroll for 2+ or Grand Melee or Ruthless Precision.
-- actions=variable,name=rtb_reroll,value=rtb_buffs<2&(buff.loaded_dice.up|!buff.grand_melee.up&!buff.ruthless_precision.up)
-- # Reroll for 2+ buffs or Ruthless Precision with Deadshot or Ace up your Sleeve.
-- actions+=/variable,name=rtb_reroll,op=set,if=azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled,value=rtb_buffs<2&(buff.loaded_dice.up|buff.ruthless_precision.remains<=cooldown.between_the_eyes.remains)
-- # Always reroll for 2+ buffs with Snake Eyes unless at 3 Ranks, then reroll everything.
-- actions+=/variable,name=rtb_reroll,op=set,if=azerite.snake_eyes.enabled,value=rtb_buffs<2|(azerite.snake_eyes.rank=3&rtb_buffs<5)
-- # Do not reroll if Snake Eyes is at 2+ Ranks and 2+ stacks of the buff (1+ stack with Broadside up)
-- actions+=/variable,name=rtb_reroll,op=reset,if=azerite.snake_eyes.rank>=2&buff.snake_eyes.stack>=2-buff.broadside.up
-- actions+=/variable,name=ambush_condition,value=combo_points.deficit>=2+2*(talent.ghostly_strike.enabled&cooldown.ghostly_strike.remains<1)+buff.broadside.up&energy>60&!buff.skull_and_crossbones.up
-- # With multiple targets, this variable is checked to decide whether some CDs should be synced with Blade Flurry
-- actions+=/variable,name=blade_flurry_sync,value=spell_targets.blade_flurry<2&raid_event.adds.in>20|buff.blade_flurry.up
-- actions+=/call_action_list,name=stealth,if=stealthed.all
-- actions+=/call_action_list,name=cds
-- # Finish at maximum CP. Substract one for each Broadside and Opportunity when Quick Draw is selected and MfD is not ready after the next second.
-- actions+=/call_action_list,name=finish,if=combo_points>=cp_max_spend-(buff.broadside.up+buff.opportunity.up)*(talent.quick_draw.enabled&(!talent.marked_for_death.enabled|cooldown.marked_for_death.remains>1))
-- actions+=/call_action_list,name=build
-- actions+=/arcane_torrent,if=energy.deficit>=15+energy.regen
-- actions+=/arcane_pulse
-- actions+=/lights_judgment

-- # Builders
-- actions.build=pistol_shot,if=combo_points.deficit>=1+buff.broadside.up+talent.quick_draw.enabled&buff.opportunity.up
-- actions.build+=/sinister_strike

-- # Cooldowns
-- actions.cds=potion,if=buff.bloodlust.react|target.time_to_die<=60|buff.adrenaline_rush.up
-- actions.cds+=/blood_fury
-- actions.cds+=/berserking
-- actions.cds+=/fireblood
-- actions.cds+=/ancestral_call
-- actions.cds+=/adrenaline_rush,if=!buff.adrenaline_rush.up&energy.time_to_max>1
-- # If adds are up, snipe the one with lowest TTD. Use when dying faster than CP deficit or without any CP.
-- actions.cds+=/marked_for_death,target_if=min:target.time_to_die,if=raid_event.adds.up&(target.time_to_die<combo_points.deficit|!stealthed.rogue&combo_points.deficit>=cp_max_spend-1)
-- # If no adds will die within the next 30s, use MfD on boss without any CP.
-- actions.cds+=/marked_for_death,if=raid_event.adds.in>30-raid_event.adds.duration&!stealthed.rogue&combo_points.deficit>=cp_max_spend-1
-- # Blade Flurry on 2+ enemies. With adds: Use if they stay for 8+ seconds or if your next charge will be ready in time for the next wave.
-- actions.cds+=/blade_flurry,if=spell_targets>=2&!buff.blade_flurry.up&(!raid_event.adds.exists|raid_event.adds.remains>8|raid_event.adds.in>(2-cooldown.blade_flurry.charges_fractional)*25)
-- actions.cds+=/ghostly_strike,if=variable.blade_flurry_sync&combo_points.deficit>=1+buff.broadside.up
-- actions.cds+=/killing_spree,if=variable.blade_flurry_sync&(energy.time_to_max>5|energy<15)
-- actions.cds+=/blade_rush,if=variable.blade_flurry_sync&energy.time_to_max>1
-- # Using Vanish/Ambush is only a very tiny increase, so in reality, you're absolutely fine to use it as a utility spell.
-- actions.cds+=/vanish,if=!stealthed.all&variable.ambush_condition
-- actions.cds+=/shadowmeld,if=!stealthed.all&variable.ambush_condition

-- # Finishers
-- # BtE over RtB rerolls with Deadshot/Ace traits or Ruthless Precision.
-- actions.finish=between_the_eyes,if=buff.ruthless_precision.up|(azerite.deadshot.enabled|azerite.ace_up_your_sleeve.enabled)&buff.roll_the_bones.up
-- actions.finish+=/slice_and_dice,if=buff.slice_and_dice.remains<target.time_to_die&buff.slice_and_dice.remains<(1+combo_points)*1.8
-- actions.finish+=/roll_the_bones,if=(buff.roll_the_bones.remains<=3|variable.rtb_reroll)&(target.time_to_die>20|buff.roll_the_bones.remains<target.time_to_die)
-- # BtE with the Ace Up Your Sleeve or Deadshot traits.
-- actions.finish+=/between_the_eyes,if=azerite.ace_up_your_sleeve.enabled|azerite.deadshot.enabled
-- actions.finish+=/dispatch

-- # Stealth
-- actions.stealth=ambush
