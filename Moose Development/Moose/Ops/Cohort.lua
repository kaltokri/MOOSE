--- **Ops** - Cohort encompassed all characteristics of SQUADRONs, PLATOONs and FLOTILLAs.
--
-- **Main Features:**
--
--    * Set parameters like livery, skill valid for all platoon members.
--    * Define modex and callsigns.
--    * Define mission types, this platoon can perform (see Ops.Auftrag#AUFTRAG).
--    * Pause/unpause platoon operations.
--
-- ===
--
-- ### Author: **funkyfranky**
-- @module Ops.Cohort
-- @image OPS_Cohort.png


--- COHORT class.
-- @type COHORT
-- @field #string ClassName Name of the class.
-- @field #number verbose Verbosity level.
-- @field #string lid Class id string for output to DCS log file.
-- @field #string name Name of the platoon.
-- @field #string templatename Name of the template group.
-- @field #string aircrafttype Type of the airframe the platoon is using.
-- @field Wrapper.Group#GROUP templategroup Template group.
-- @field #table assets Cohort assets.
-- @field #table missiontypes Capabilities (mission types and performances) of the platoon.
-- @field #number maintenancetime Time in seconds needed for maintenance of a returned flight.
-- @field #number repairtime Time in seconds for each
-- @field #string livery Livery of the platoon.
-- @field #number skill Skill of platoon members.
-- @field Ops.Legion#LEGION legion The LEGION object the cohort belongs to.
-- @field #number Ngroups Number of asset flight groups this platoon has. 
-- @field #number engageRange Mission range in meters.
-- @field #string attribute Generalized attribute of the platoon template group.
-- @field #table tacanChannel List of TACAN channels available to the platoon.
-- @field #number radioFreq Radio frequency in MHz the cohort uses.
-- @field #number radioModu Radio modulation the cohort uses.
-- @field #table tacanChannel List of TACAN channels available to the cohort.
-- @extends Core.Fsm#FSM

--- *It is unbelievable what a platoon of twelve aircraft did to tip the balance.* -- Adolf Galland
--
-- ===
--
-- ![Banner Image](..\Presentations\OPS\Cohort\_Main.png)
--
-- # The COHORT Concept
-- 
-- A COHORT is essential part of an BRIGADE and consists of **one** type of aircraft. 
--
--
--
-- @field #COHORT
COHORT = {
  ClassName      = "COHORT",
  verbose        =     0,
  lid            =   nil,
  name           =   nil,
  templatename   =   nil,
  assets         =    {},
  missiontypes   =    {},
  repairtime     =     0,
  maintenancetime=     0,
  livery         =   nil,
  skill          =   nil,
  legion         =   nil,
  Ngroups        =   nil,
  engageRange    =   nil,
  tacanChannel   =    {},  
}

--- COHORT class version.
-- @field #string version
COHORT.version="0.0.1"

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO list
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

-- TODO: A lot!
-- TODO: Make general so that PLATOON and SQUADRON can inherit this class.

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Constructor
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Create a new COHORT object and start the FSM.
-- @param #COHORT self
-- @param #string TemplateGroupName Name of the template group.
-- @param #number Ngroups Number of asset groups of this platoon. Default 3.
-- @param #string CohortName Name of the platoon, e.g. "VFA-37".
-- @return #COHORT self
function COHORT:New(TemplateGroupName, Ngroups, CohortName)

  -- Inherit everything from FSM class.
  local self=BASE:Inherit(self, FSM:New()) -- #COHORT

  -- Name of the template group.
  self.templatename=TemplateGroupName

  -- Cohort name.
  self.name=tostring(CohortName or TemplateGroupName)
  
  -- Set some string id for output to DCS.log file.
  self.lid=string.format("COHORT %s | ", self.name)
  
  -- Template group.
  self.templategroup=GROUP:FindByName(self.templatename)
  
  -- Check if template group exists.
  if not self.templategroup then
    self:E(self.lid..string.format("ERROR: Template group %s does not exist!", tostring(self.templatename)))
    return nil
  end
  
  -- Defaults.
  self.Ngroups=Ngroups or 3  
  self:SetMissionRange()
  self:SetSkill(AI.Skill.GOOD)
  
  -- Generalized attribute.
  self.attribute=self.templategroup:GetAttribute()
  
  -- Aircraft type.
  self.aircrafttype=self.templategroup:GetTypeName()

  -- Start State.
  self:SetStartState("Stopped")
  
  -- Add FSM transitions.
  --                 From State  -->   Event        -->     To State
  self:AddTransition("Stopped",       "Start",              "OnDuty")      -- Start FSM.
  self:AddTransition("*",             "Status",             "*")           -- Status update.
  
  self:AddTransition("OnDuty",        "Pause",              "Paused")      -- Pause platoon.
  self:AddTransition("Paused",        "Unpause",            "OnDuty")      -- Unpause platoon.
  
  self:AddTransition("*",             "Stop",               "Stopped")     -- Stop platoon.


  ------------------------
  --- Pseudo Functions ---
  ------------------------

  --- Triggers the FSM event "Start". Starts the COHORT. Initializes parameters and starts event handlers.
  -- @function [parent=#COHORT] Start
  -- @param #COHORT self

  --- Triggers the FSM event "Start" after a delay. Starts the COHORT. Initializes parameters and starts event handlers.
  -- @function [parent=#COHORT] __Start
  -- @param #COHORT self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Stop". Stops the COHORT and all its event handlers.
  -- @param #COHORT self

  --- Triggers the FSM event "Stop" after a delay. Stops the COHORT and all its event handlers.
  -- @function [parent=#COHORT] __Stop
  -- @param #COHORT self
  -- @param #number delay Delay in seconds.

  --- Triggers the FSM event "Status".
  -- @function [parent=#COHORT] Status
  -- @param #COHORT self

  --- Triggers the FSM event "Status" after a delay.
  -- @function [parent=#COHORT] __Status
  -- @param #COHORT self
  -- @param #number delay Delay in seconds.

  return self
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- User functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Set livery painted on all platoon aircraft.
-- Note that the livery name in general is different from the name shown in the mission editor.
-- 
-- Valid names are the names of the **livery directories**. Check out the folder in your DCS installation for:
-- 
-- * Full modules: `DCS World OpenBeta\CoreMods\aircraft\<Aircraft Type>\Liveries\<Aircraft Type>\<Livery Name>`
-- * AI units: `DCS World OpenBeta\Bazar\Liveries\<Aircraft Type>\<Livery Name>`
-- 
-- The folder name `<Livery Name>` is the string you want.
-- 
-- Or personal liveries you have installed somewhere in your saved games folder.
--  
-- @param #COHORT self
-- @param #string LiveryName Name of the livery.
-- @return #COHORT self
function COHORT:SetLivery(LiveryName)
  self.livery=LiveryName
  return self
end

--- Set skill level of all platoon team members.
-- @param #COHORT self
-- @param #string Skill Skill of all flights.
-- @usage myplatoon:SetSkill(AI.Skill.EXCELLENT)
-- @return #COHORT self
function COHORT:SetSkill(Skill)
  self.skill=Skill
  return self
end

--- Set verbosity level.
-- @param #COHORT self
-- @param #number VerbosityLevel Level of output (higher=more). Default 0.
-- @return #COHORT self
function COHORT:SetVerbosity(VerbosityLevel)
  self.verbose=VerbosityLevel or 0
  return self
end

--- Set turnover and repair time. If an asset returns from a mission, it will need some time until the asset is available for further missions.
-- @param #COHORT self
-- @param #number MaintenanceTime Time in minutes it takes until a flight is combat ready again. Default is 0 min.
-- @param #number RepairTime Time in minutes it takes to repair a flight for each life point taken. Default is 0 min.
-- @return #COHORT self
function COHORT:SetTurnoverTime(MaintenanceTime, RepairTime)
  self.maintenancetime=MaintenanceTime and MaintenanceTime*60 or 0
  self.repairtime=RepairTime and RepairTime*60 or 0
  return self
end

--- Set radio frequency and modulation the cohort uses.
-- @param #COHORT self
-- @param #number Frequency Radio frequency in MHz. Default 251 MHz.
-- @param #number Modulation Radio modulation. Default 0=AM.
-- @usage myplatoon:SetSkill(AI.Skill.EXCELLENT)
-- @return #COHORT self
function COHORT:SetRadio(Frequency, Modulation)
  self.radioFreq=Frequency or 251
  self.radioModu=Modulation or radio.modulation.AM
  return self
end

--- Set number of units in groups.
-- @param #COHORT self
-- @param #number nunits Number of units. Must be >=1 and <=4. Default 2.
-- @return #COHORT self
function COHORT:SetGrouping(nunits)
  self.ngrouping=nunits or 2
  if self.ngrouping<1 then self.ngrouping=1 end
  if self.ngrouping>4 then self.ngrouping=4 end
  return self
end

--- Set mission types this platoon is able to perform.
-- @param #COHORT self
-- @param #table MissionTypes Table of mission types. Can also be passed as a #string if only one type.
-- @param #number Performance Performance describing how good this mission can be performed. Higher is better. Default 50. Max 100.
-- @return #COHORT self
function COHORT:AddMissionCapability(MissionTypes, Performance)

  -- Ensure Missiontypes is a table.
  if MissionTypes and type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end
  
  -- Set table.
  self.missiontypes=self.missiontypes or {}
  
  for _,missiontype in pairs(MissionTypes) do
  
    -- Check not to add the same twice.  
    if self:CheckMissionCapability(missiontype, self.missiontypes) then
      self:E(self.lid.."WARNING: Mission capability already present! No need to add it twice.")
      -- TODO: update performance.
    else
  
      local capability={} --Ops.Auftrag#AUFTRAG.Capability
      capability.MissionType=missiontype
      capability.Performance=Performance or 50
      table.insert(self.missiontypes, capability)
      
    end
  end
  
  -- Debug info.
  self:T2(self.missiontypes)
  
  return self
end

--- Get mission types this platoon is able to perform.
-- @param #COHORT self
-- @return #table Table of mission types. Could be empty {}.
function COHORT:GetMissionTypes()

  local missiontypes={}
  
  for _,Capability in pairs(self.missiontypes) do
    local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
    table.insert(missiontypes, capability.MissionType)  
  end

  return missiontypes
end

--- Get mission capabilities of this platoon.
-- @param #COHORT self
-- @return #table Table of mission capabilities.
function COHORT:GetMissionCapabilities()
  return self.missiontypes
end

--- Get mission performance for a given type of misson.
-- @param #COHORT self
-- @param #string MissionType Type of mission.
-- @return #number Performance or -1.
function COHORT:GetMissionPeformance(MissionType)

  for _,Capability in pairs(self.missiontypes) do
    local capability=Capability --Ops.Auftrag#AUFTRAG.Capability
    if capability.MissionType==MissionType then
      return capability.Performance
    end
  end

  return -1
end

--- Set max mission range. Only missions in a circle of this radius around the platoon airbase are executed.
-- @param #COHORT self
-- @param #number Range Range in NM. Default 100 NM.
-- @return #COHORT self
function COHORT:SetMissionRange(Range)
  self.engageRange=UTILS.NMToMeters(Range or 100)
  return self
end

--- Set call sign.
-- @param #COHORT self
-- @param #number Callsign Callsign from CALLSIGN.Aircraft, e.g. "Chevy" for CALLSIGN.Aircraft.CHEVY.
-- @param #number Index Callsign index, Chevy-**1**.
-- @return #COHORT self
function COHORT:SetCallsign(Callsign, Index)
  self.callsignName=Callsign
  self.callsignIndex=Index
  return self
end

--- Set modex.
-- @param #COHORT self
-- @param #number Modex A number like 100.
-- @param #string Prefix A prefix string, which is put before the `Modex` number.
-- @param #string Suffix A suffix string, which is put after the `Modex` number. 
-- @return #COHORT self
function COHORT:SetModex(Modex, Prefix, Suffix)
  self.modex=Modex
  self.modexPrefix=Prefix
  self.modexSuffix=Suffix
  return self
end

--- Set Legion.
-- @param #COHORT self
-- @param Ops.Legion#LEGION Legion The Legion.
-- @return #COHORT self
function COHORT:SetLegion(Legion)
  self.legion=Legion
  return self
end

--- Add asset to cohort.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The warehouse asset.
-- @return #COHORT self
function COHORT:AddAsset(Asset)
  self:T(self.lid..string.format("Adding asset %s of type %s", Asset.spawngroupname, Asset.unittype))
  Asset.squadname=self.name
  table.insert(self.assets, Asset)
  return self
end

--- Remove asset from chort.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
-- @return #COHORT self
function COHORT:DelAsset(Asset)
  for i,_asset in pairs(self.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    if Asset.uid==asset.uid then
      self:T2(self.lid..string.format("Removing asset %s", asset.spawngroupname))
      table.remove(self.assets, i)
      break
    end
  end
  return self
end

--- Remove asset group from cohort.
-- @param #COHORT self
-- @param #string GroupName Name of the asset group.
-- @return #COHORT self
function COHORT:DelGroup(GroupName)
  for i,_asset in pairs(self.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    if GroupName==asset.spawngroupname then
      self:T2(self.lid..string.format("Removing asset %s", asset.spawngroupname))
      table.remove(self.assets, i)
      break
    end
  end
  return self
end

--- Get name of the platoon
-- @param #COHORT self
-- @return #string Name of the platoon.
function COHORT:GetName()
  return self.name
end

--- Get radio frequency and modulation.
-- @param #COHORT self
-- @return #number Radio frequency in MHz.
-- @return #number Radio Modulation (0=AM, 1=FM).
function COHORT:GetRadio()
  return self.radioFreq, self.radioModu
end

--- Create a callsign for the asset.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The warehouse asset.
-- @return #COHORT self
function COHORT:GetCallsign(Asset)

  if self.callsignName then
  
    Asset.callsign={}
  
    for i=1,Asset.nunits do
    
      local callsign={}
      
      callsign[1]=self.callsignName
      callsign[2]=math.floor(self.callsigncounter / 10)
      callsign[3]=self.callsigncounter % 10
      if callsign[3]==0 then
        callsign[3]=1
        self.callsigncounter=self.callsigncounter+2
      else
        self.callsigncounter=self.callsigncounter+1
      end
    
      Asset.callsign[i]=callsign
      
      self:T3({callsign=callsign})
    
      --TODO: there is also a table entry .name, which is a string.
    end
  
  
  end

end

--- Create a modex for the asset.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The warehouse asset.
-- @return #COHORT self
function COHORT:GetModex(Asset)

  if self.modex then
  
    Asset.modex={}
  
    for i=1,Asset.nunits do
    
      Asset.modex[i]=string.format("%03d", self.modex+self.modexcounter)
      
      self.modexcounter=self.modexcounter+1
      
      self:T3({modex=Asset.modex[i]})
    
    end
    
  end
  
end


--- Add TACAN channels to the platoon. Note that channels can only range from 1 to 126.
-- @param #COHORT self
-- @param #number ChannelMin Channel.
-- @param #number ChannelMax Channel.
-- @return #COHORT self
-- @usage mysquad:AddTacanChannel(64,69)  -- adds channels 64, 65, 66, 67, 68, 69
function COHORT:AddTacanChannel(ChannelMin, ChannelMax)

  ChannelMax=ChannelMax or ChannelMin
  
  if ChannelMin>126 then
    self:E(self.lid.."ERROR: TACAN Channel must be <= 126! Will not add to available channels")
    return self
  end
  if ChannelMax>126 then
    self:E(self.lid.."WARNING: TACAN Channel must be <= 126! Adjusting ChannelMax to 126")
    ChannelMax=126
  end

  for i=ChannelMin,ChannelMax do
    self.tacanChannel[i]=true
  end

  return self
end

--- Get an unused TACAN channel.
-- @param #COHORT self
-- @return #number TACAN channel or *nil* if no channel is free.
function COHORT:FetchTacan()

  -- Get the smallest free channel if there is one.
  local freechannel=nil  
  for channel,free in pairs(self.tacanChannel) do
    if free then      
      if freechannel==nil or channel<freechannel then
        freechannel=channel
      end      
    end
  end
  
  if freechannel then
    self:T(self.lid..string.format("Checking out Tacan channel %d", freechannel))
    self.tacanChannel[freechannel]=false
  end

  return freechannel
end

--- "Return" a used TACAN channel.
-- @param #COHORT self
-- @param #number channel The channel that is available again.
function COHORT:ReturnTacan(channel)
  self:T(self.lid..string.format("Returning Tacan channel %d", channel))
  self.tacanChannel[channel]=true
end

--- Check if platoon is "OnDuty".
-- @param #COHORT self
-- @return #boolean If true, squdron is in state "OnDuty".
function COHORT:IsOnDuty()
  return self:Is("OnDuty")
end

--- Check if platoon is "Stopped".
-- @param #COHORT self
-- @return #boolean If true, squdron is in state "Stopped".
function COHORT:IsStopped()
  return self:Is("Stopped")
end

--- Check if platoon is "Paused".
-- @param #COHORT self
-- @return #boolean If true, squdron is in state "Paused".
function COHORT:IsPaused()
  return self:Is("Paused")
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Start & Status
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- On after Start event. Starts the FLIGHTGROUP FSM and event handlers.
-- @param #COHORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COHORT:onafterStart(From, Event, To)

  -- Short info.
  local text=string.format("Starting %s v%s %s", self.ClassName, self.version, self.name)
  self:I(self.lid..text)

  -- Start the status monitoring.
  self:__Status(-1)
end

--- Check asset status.
-- @param #COHORT self
function COHORT:_CheckAssetStatus()

  if self.verbose>=2 and #self.assets>0 then
  
    local text=""
    for j,_asset in pairs(self.assets) do
      local asset=_asset  --Functional.Warehouse#WAREHOUSE.Assetitem
  
      -- Text.
      text=text..string.format("\n[%d] %s (%s*%d): ", j, asset.spawngroupname, asset.unittype, asset.nunits)
      
      if asset.spawned then
      
        ---
        -- Spawned
        ---
  
        -- Mission info.
        local mission=self.legion and self.legion:GetAssetCurrentMission(asset) or false
        if mission then
          local distance=asset.flightgroup and UTILS.MetersToNM(mission:GetTargetDistance(asset.flightgroup.group:GetCoordinate())) or 0
          text=text..string.format("Mission %s - %s: Status=%s, Dist=%.1f NM", mission.name, mission.type, mission.status, distance)
        else
          text=text.."Mission None"
        end
          
        -- Flight status.
        text=text..", Flight: "
        if asset.flightgroup and asset.flightgroup:IsAlive() then
          local status=asset.flightgroup:GetState()
          text=text..string.format("%s", status)
          
          if asset.flightgroup:IsFlightgroup() then
            local fuelmin=asset.flightgroup:GetFuelMin()
            local fuellow=asset.flightgroup:IsFuelLow()
            local fuelcri=asset.flightgroup:IsFuelCritical()            
            text=text..string.format("Fuel=%d", fuelmin)
            if fuelcri then
              text=text.." (Critical!)"
            elseif fuellow then
              text=text.." (Low)"
            end
          end
          
          local lifept, lifept0=asset.flightgroup:GetLifePoints()
          text=text..string.format(", Life=%d/%d", lifept, lifept0)
          
          local ammo=asset.flightgroup:GetAmmoTot()
          text=text..string.format(", Ammo=%d [G=%d, R=%d, B=%d, M=%d]", ammo.Total,ammo.Guns, ammo.Rockets, ammo.Bombs, ammo.Missiles)
        else
          text=text.."N/A"
        end

        -- Payload info.
        if asset.flightgroup:IsFlightgroup() then
          local payload=asset.payload and table.concat(self.legion:GetPayloadMissionTypes(asset.payload), ", ") or "None"
          text=text..", Payload={"..payload.."}"
        end
     
      else
  
        ---
        -- In Stock
        ---
        
        text=text..string.format("In Stock")
        
        if self:IsRepaired(asset) then
          text=text..", Combat Ready"
        else
        
          text=text..string.format(", Repaired in %d sec", self:GetRepairTime(asset))

          if asset.damage then
            text=text..string.format(" (Damage=%.1f)", asset.damage)
          end
        end
  
        if asset.Treturned then
          local T=timer.getAbsTime()-asset.Treturned
          text=text..string.format(", Returned for %d sec", T)
        end
      
      end
    end
    self:I(self.lid..text)
  end

end

--- On after "Stop" event.
-- @param #COHORT self
-- @param #string From From state.
-- @param #string Event Event.
-- @param #string To To state.
function COHORT:onafterStop(From, Event, To)

  -- Debug info.
  self:I(self.lid.."STOPPING Cohort and removing all assets!")

  -- Remove all assets.
  for i=#self.assets,1,-1 do
    local asset=self.assets[i]
    self:DelAsset(asset)
  end

  -- Clear call scheduler.
  self.CallScheduler:Clear()
  
end

-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-- Misc Functions
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

--- Check if there is a platoon that can execute a given mission.
-- We check the mission type, the refuelling system, engagement range
-- @param #COHORT self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @return #boolean If true, Cohort can do that type of mission.
function COHORT:CanMission(Mission)
  
  local cando=true
  
  -- On duty?=  
  if not self:IsOnDuty() then
    self:T(self.lid..string.format("Cohort in not OnDuty but in state %s. Cannot do mission %s with target %s", self:GetState(), Mission.name, Mission:GetTargetName()))
    return false
  end

  -- Check mission type. WARNING: This assumes that all assets of the cohort can do the same mission types!
  if not self:CheckMissionType(Mission.type, self:GetMissionTypes()) then
    self:T(self.lid..string.format("INFO: Cohort cannot do mission type %s (%s, %s)", Mission.type, Mission.name, Mission:GetTargetName()))
    return false
  end
  
  -- Check that tanker mission has the correct refuelling system.
  if Mission.type==AUFTRAG.Type.TANKER then
  
    if Mission.refuelSystem and Mission.refuelSystem==self.tankerSystem then
      -- Correct refueling system.
    else
      self:T(self.lid..string.format("INFO: Wrong refueling system requested=%s != %s=available", tostring(Mission.refuelSystem), tostring(self.tankerSystem)))
      return false
    end
  
  end
  
  -- Distance to target.
  local TargetDistance=Mission:GetTargetDistance(self.legion:GetCoordinate())
  
  -- Max engage range.
  local engagerange=Mission.engageRange and math.max(self.engageRange, Mission.engageRange) or self.engageRange
      
  -- Set range is valid. Mission engage distance can overrule the cohort engage range.
  if TargetDistance>engagerange then
    self:I(self.lid..string.format("INFO: Cohort is not in range. Target dist=%d > %d NM max mission Range", UTILS.MetersToNM(TargetDistance), UTILS.MetersToNM(engagerange)))
    return false
  end
  
  return true
end

--- Count assets in legion warehouse stock.
-- @param #COHORT self
-- @param #boolean InStock If true, only assets that are in the warehouse stock/inventory are counted.
-- @param #table MissionTypes (Optional) Count only assest that can perform certain mission type(s). Default is all types.
-- @param #table Attributes (Optional) Count only assest that have a certain attribute(s), e.g. `WAREHOUSE.Attribute.AIR_BOMBER`.
-- @return #number Number of assets.
function COHORT:CountAssets(InStock, MissionTypes, Attributes)

  local N=0
  for _,_asset in pairs(self.assets) do
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    if MissionTypes==nil or self:CheckMissionCapability(MissionTypes, self.missiontypes) then
      if Attributes==nil or self:CheckAttribute(Attributes) then
        if asset.spawned then
          if not InStock then
            N=N+1 --Spawned but we also count the spawned ones.
          end      
        else
          N=N+1 --This is in stock.
        end
      end
    end
  end

  return N
end

--- Get assets for a mission.
-- @param #COHORT self
-- @param Ops.Auftrag#AUFTRAG Mission The mission.
-- @param #number Nplayloads Number of payloads available.
-- @return #table Assets that can do the required mission.
function COHORT:RecruitAssets(Mission, Npayloads)

  -- Number of payloads available.
  Npayloads=Npayloads or self.legion:CountPayloadsInStock(Mission.type, self.aircrafttype, Mission.payloads)      

  local assets={}

  -- Loop over assets.
  for _,_asset in pairs(self.assets) do  
    local asset=_asset --Functional.Warehouse#WAREHOUSE.Assetitem
    
    
    -- Check if asset is currently on a mission (STARTED or QUEUED).
    if self.legion:IsAssetOnMission(asset) then

      ---
      -- Asset is already on a mission.
      ---

      -- Check if this asset is currently on a GCICAP mission (STARTED or EXECUTING).
      if self.legion:IsAssetOnMission(asset, AUFTRAG.Type.GCICAP) and Mission.type==AUFTRAG.Type.INTERCEPT then

        -- Check if the payload of this asset is compatible with the mission.
        -- Note: we do not check the payload as an asset that is on a GCICAP mission should be able to do an INTERCEPT as well!
        self:I(self.lid.."Adding asset on GCICAP mission for an INTERCEPT mission")
        table.insert(assets, asset)
        
      end      
    
    else
    
      ---
      -- Asset as NO current mission
      ---

      if asset.spawned then
      
        ---
        -- Asset is already SPAWNED (could be uncontrolled on the airfield or inbound after another mission)
        ---
      
        local flightgroup=asset.flightgroup
      
        -- Firstly, check if it has the right payload.
        if self:CheckMissionCapability(Mission.type, asset.payload.capabilities) and flightgroup and flightgroup:IsAlive() then
      
          -- Assume we are ready and check if any condition tells us we are not.
          local combatready=true
  
          if Mission.type==AUFTRAG.Type.INTERCEPT then
            combatready=flightgroup:CanAirToAir()
          else
            local excludeguns=Mission.type==AUFTRAG.Type.BOMBING or Mission.type==AUFTRAG.Type.BOMBRUNWAY or Mission.type==AUFTRAG.Type.BOMBCARPET or Mission.type==AUFTRAG.Type.SEAD or Mission.type==AUFTRAG.Type.ANTISHIP
            combatready=flightgroup:CanAirToGround(excludeguns)
          end
          
          -- No more attacks if fuel is already low. Safety first!
          if flightgroup:IsFuelLow() then
            combatready=false
          end
          
          -- Check if in a state where we really do not want to fight any more.
          if flightgroup:IsHolding() or flightgroup:IsLanding() or flightgroup:IsLanded() or flightgroup:IsArrived() or flightgroup:IsDead() or flightgroup:IsStopped() then
            combatready=false
          end
      
          -- This asset is "combatready".
          if combatready then
            self:I(self.lid.."Adding SPAWNED asset to ANOTHER mission as it is COMBATREADY")
            table.insert(assets, asset)
          end
        
        end
        
      else
      
        ---
        -- Asset is still in STOCK
        ---          
      
        -- Check that asset is not already requested for another mission.
        if Npayloads>0 and self:IsRepaired(asset) and (not asset.requested) then
                    
          -- Add this asset to the selection.
          table.insert(assets, asset)
          
          -- Reduce number of payloads so we only return the number of assets that could do the job.
          Npayloads=Npayloads-1
          
        end
        
      end      
    end    
  end -- loop over assets

  return assets
end


--- Get the time an asset needs to be repaired.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
-- @return #number Time in seconds until asset is repaired.
function COHORT:GetRepairTime(Asset)

  if Asset.Treturned then
  
    local t=self.maintenancetime    
    t=t+Asset.damage*self.repairtime
    
    -- Seconds after returned.
    local dt=timer.getAbsTime()-Asset.Treturned
  
    local T=t-dt
    
    return T
  else
    return 0
  end

end

--- Checks if a mission type is contained in a table of possible types.
-- @param #COHORT self
-- @param Functional.Warehouse#WAREHOUSE.Assetitem Asset The asset.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function COHORT:IsRepaired(Asset)

  if Asset.Treturned then
    local Tnow=timer.getAbsTime()
    local Trepaired=Asset.Treturned+self.maintenancetime
    if Tnow>=Trepaired then
      return true
    else
      return false
    end
  
  else
    return true
  end

end


--- Checks if a mission type is contained in a table of possible types.
-- @param #COHORT self
-- @param #string MissionType The requested mission type.
-- @param #table PossibleTypes A table with possible mission types.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function COHORT:CheckMissionType(MissionType, PossibleTypes)

  if type(PossibleTypes)=="string" then
    PossibleTypes={PossibleTypes}
  end

  for _,canmission in pairs(PossibleTypes) do
    if canmission==MissionType then
      return true
    end   
  end

  return false
end

--- Check if a mission type is contained in a list of possible capabilities.
-- @param #COHORT self
-- @param #table MissionTypes The requested mission type. Can also be passed as a single mission type `#string`.
-- @param #table Capabilities A table with possible capabilities.
-- @return #boolean If true, the requested mission type is part of the possible mission types.
function COHORT:CheckMissionCapability(MissionTypes, Capabilities)

  if type(MissionTypes)~="table" then
    MissionTypes={MissionTypes}
  end

  for _,cap in pairs(Capabilities) do
    local capability=cap --Ops.Auftrag#AUFTRAG.Capability
    for _,MissionType in pairs(MissionTypes) do
      if capability.MissionType==MissionType then
        return true
      end
    end
  end

  return false
end

--- Check if the platoon attribute matches the given attribute(s).
-- @param #COHORT self
-- @param #table Attributes The requested attributes. See `WAREHOUSE.Attribute` enum. Can also be passed as a single attribute `#string`.
-- @return #boolean If true, the cohort has the requested attribute.
function COHORT:CheckAttribute(Attributes)

  if type(Attributes)~="table" then
    Attributes={Attributes}
  end

  for _,attribute in pairs(Attributes) do
    if attribute==self.attribute then
      return true
    end
  end

  return false
end


-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

