--- ============================ HEADER ============================
--- ======= LOCALIZE =======
  -- Addon
  local addonName, addonTable = ...;
  -- HeroRotation
  local HR = HeroRotation;
  -- HeroLib
  local HL = HeroLib;
  -- File Locals
  local GUI = HL.GUI;
  local CreateChildPanel = GUI.CreateChildPanel;
  local CreatePanelOption = GUI.CreatePanelOption;
  local CreateARPanelOption = HR.GUI.CreateARPanelOption;
  local CreateARPanelOptions = HR.GUI.CreateARPanelOptions;

--- ============================ CONTENT ============================
  -- All settings here should be moved into the GUI someday.
  HR.GUISettings.APL.Monk = {
    Commons = {
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        -- Abilities

      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        --Trinkets
        Trinkets               = true,
        -- Racials
        Racials                = true,
        -- Abilities
        SpearHandStrike = true,
      }
    },
    Brewmaster = {
      UsePotions = true,
      MaintainISBAlways = true,
      FocusOnDefense = true,

      -- Purify
      Purify = {
        Enabled = true,
        Low = false,
        Medium = true,
        High = true
      },
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        -- Abilities
        InvokeNiuzaotheBlackOx = true,
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Racials
        ArcaneTorrent          = true,
        -- Abilities
        BlackOxBrew            = true,
        IronskinBrew           = true,
        PurifyingBrew          = true,
      }
    },
    Windwalker = {
      -- {Display GCD as OffGCD, ForceReturn}
      GCDasOffGCD = {
        -- Abilities
        InvokeXuenTheWhiteTiger = true,
        TouchOfDeath            = true,
        Serenity                = true,
      },
      -- {Display OffGCD as OffGCD, ForceReturn}
      OffGCDasOffGCD = {
        -- Racials
        ArcaneTorrent = true
        -- Abilities
      }
    }
  };
  HR.GUI.LoadSettingsRecursively(HR.GUISettings);
  
  -- Child Panels
  local ARPanel = HR.GUI.Panel;
  local CP_Monk = CreateChildPanel(ARPanel, "Monk");
  local CP_Windwalker = CreateChildPanel(CP_Monk, "Windwalker");
  local CP_Brewmaster = CreateChildPanel(CP_Monk, "Brewmaster");
  -- Monk
  CreateARPanelOptions(CP_Monk, "APL.Monk.Commons");
  -- Windwalker
  CreateARPanelOptions(CP_Windwalker, "APL.Monk.Windwalker");
  -- BrewMaster
  CreateARPanelOptions(CP_Brewmaster, "APL.Monk.Brewmaster");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.Purify.Enabled", "Purify", "Enable or disable Purify recommendations.");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.Purify.Low", "Purify: Low", "Enable or disable Purify recommendations when the stagger is low.");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.Purify.Medium", "Purify: Medium", "Enable or disable Purify recommendations when the stagger is medium.");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.Purify.High", "Purify: High", "Enable or disable Purify recommendations when the stagger is high.");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.MaintainISBAlways", "Maintain ISB Always", "Maintain ISB When not tanking");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.FocusOnDefense", "Focus On Defensive Rotation when tanking", "Focus On Defensive Rotation when tanking");
  CreatePanelOption("CheckButton", CP_Brewmaster, "APL.Monk.Brewmaster.UsePotions", "Use Potions", "Use Potions with rotation");
