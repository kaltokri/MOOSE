--- **Core** - Spawn statics.
--  
-- ===
-- 
-- ## Features:
-- 
--   * Spawn new statics from a static already defined in the mission editor.
--   * Spawn new statics from a given template.
--   * Spawn with a custom heading and location.
--   * Spawn within a zone.
-- 
-- ===
-- 
-- # Demo Missions
-- 
-- ## [SPAWNSTATIC Demo Missions](https://github.com/FlightControl-Master/MOOSE_MISSIONS/tree/master/SPS%20-%20Spawning%20Statics)
--
-- 
-- ===
-- 
-- # YouTube Channel
-- 
-- ## [SPAWNSTATIC YouTube Channel]() [No videos yet!]
-- 
-- ===
-- 
-- ### Author: **FlightControl**
-- ### Contributions: **funkyfranky**
-- 
-- ===
-- 
-- @module Core.SpawnStatic
-- @image Core_Spawnstatic.JPG



--- @type SPAWNSTATIC
-- @field #string SpawnTemplatePrefix Name of the template group.
-- @field #number CountryID Country ID.
-- @field #number CoalitionID Coalition ID.
-- @field #number CategoryID Category ID.
-- @field #number SpawnIndex Running number increased with each new Spawn.
-- @field Wrapper.Unit#UNIT InitLinkUnit The unit the static is linked to.
-- @field #number InitOffsetX Link offset X coordinate.
-- @field #number InitOffsetY Link offset Y coordinate.
-- @field #number InitOffsetAngle Link offset angle in degrees.
-- @field #number InitStaticHeading Heading of the static.
-- @field #string InitStaticLivery Livery for aircraft.
-- @field #string InitStaticShape Shape of teh static.
-- @field #string InitStaticType Type of the static.
-- @field #string InitStaticName Name of the static.
-- @field Core.Point#COORDINATE InitStaticCoordinate Coordinate where to spawn the static.
-- @field #boolean InitDead Set static to be dead if true.
-- @extends Core.Base#BASE


--- Allows to spawn dynamically new @{Static}s.
-- Through creating a copy of an existing static object template as defined in the Mission Editor (ME),
-- SPAWNSTATIC can retireve the properties of the defined static object template (like type, category etc), and "copy"
-- these properties to create a new static object and place it at the desired coordinate.
-- 
-- New spawned @{Static}s get **the same name** as the name of the template Static, 
-- or gets the given name when a new name is provided at the Spawn method.  
-- By default, spawned @{Static}s will follow a naming convention at run-time:
-- 
--   * Spawned @{Static}s will have the name _StaticName_#_nnn_, where _StaticName_ is the name of the **Template Static**, 
--   and _nnn_ is a **counter from 0 to 99999**.
-- 
--   
-- ## SPAWNSTATIC construction methods
-- 
-- Create a new SPAWNSTATIC object with the @{#SPAWNSTATIC.NewFromStatic}():
-- 
--   * @{#SPAWNSTATIC.NewFromStatic}(): Creates a new SPAWNSTATIC object given a name that is used as the base of the naming of each spawned Static.
--
-- ## **Spawn** methods
-- 
-- Statics can be spawned at different times and methods:
-- 
--   * @{#SPAWNSTATIC.SpawnFromPointVec2}(): Spawn a new group from a POINT_VEC2 coordinate. The group will be spawned at land height.
--   * @{#SPAWNSTATIC.SpawnFromZone}(): Spawn a new group in a @{Zone}.
--  
-- @field #SPAWNSTATIC SPAWNSTATIC
-- 
SPAWNSTATIC = {
  ClassName  = "SPAWNSTATIC",
  SpawnIndex = 0,
}

--- Static template table data.
-- @type SPAWNSTATIC.TemplateData
-- @field #string name Name of the static.
-- @field #string type Type of the static.
-- @field #string category Category of the static.
-- @field #number x X-coordinate of the static.
-- @field #number y Y-coordinate of teh static.
-- @field #number heading Heading in rad.
-- @field #boolean dead Static is dead if true.
-- @field #string livery_id Livery name.
-- @field #number unitId Unit ID.
-- @field #number groupId Group ID.
-- @field #table offsets Offset parameters when linked to a unit.

--- Creates the main object to spawn a @{Static} defined in the mission editor (ME).
-- @param #SPAWNSTATIC self
-- @param #string SpawnTemplateName Name of the static object in the ME. Each new static will have the name starting with this prefix.
-- @param DCS#country.id SpawnCountryID (Optional) The ID of the country.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromStatic(SpawnTemplateName, SpawnCountryID)

	local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC
  
	local TemplateStatic, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate(SpawnTemplateName)
	
	if TemplateStatic then
		self.SpawnTemplatePrefix = SpawnTemplateName
		self.TemplateStaticUnit  = UTILS.DeepCopy(TemplateStatic.units[1])
		self.CountryID           = SpawnCountryID or CountryID
		self.CategoryID          = CategoryID
		self.CoalitionID         = CoalitionID
		self.SpawnIndex          = 0
	else
		error( "SPAWNSTATIC:New: There is no static declared in the mission editor with SpawnTemplatePrefix = '" .. tostring(SpawnTemplateName) .. "'" )
	end

  self:SetEventPriority( 5 )

	return self
end

--- Creates the main object to spawn a @{Static} given a template table.
-- @param #SPAWNSTATIC self
-- @param #table SpawnTemplate Template used for spawning.
-- @param DCS#country.id CountryID The ID of the country. Default `country.id.USA`.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromTemplate(SpawnTemplate, CountryID)

  local self = BASE:Inherit( self, BASE:New() ) -- #SPAWNSTATIC
  
  self.TemplateStaticUnit  = UTILS.DeepCopy(SpawnTemplate)
  self.SpawnTemplatePrefix = SpawnTemplate.name
  self.CountryID           = CountryID or country.id.USA
  
  return self
end

--- Creates the main object to spawn a @{Static} from a given type.
-- NOTE that you have to init many other parameters as spawn coordinate etc.
-- @param #SPAWNSTATIC self
-- @param #string StaticType Type of the static.
-- @param #string StaticCategory Category of the static, e.g. "Planes".
-- @param DCS#country.id CountryID The ID of the country. Default `country.id.USA`.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:NewFromType(StaticType, StaticCategory, CountryID)

  self.InitStaticType=StaticType
  self.InitStaticCategory=StaticCategory
  self.CountryID=CountryID or country.id.USA
  
  self.InitStaticCoordinate=COORDINATE:New(0, 0, 0)

  return self
end

--- Initialize heading of the spawned static.
-- @param #SPAWNSTATIC self
-- @param Core.Point#COORDINATE Coordinate Position where the static is spawned.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitCoordinate(Coordinate)
  self.InitStaticCoordinate=Coordinate
  return self
end

--- Initialize heading of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #number Heading The heading in degrees.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitHeading(Heading)
  self.InitStaticHeading=Heading
  return self
end

--- Initialize livery of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #string LiveryName Name of the livery to use.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitLivery(LiveryName)
  self.InitStaticLivery=LiveryName
  return self
end

--- Initialize type of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #string StaticType Type of the static, e.g. "FA-18C_hornet".
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitType(StaticType)
  self.InitStaticType=StaticType
  return self
end

--- Initialize shape of the spawned static. Required by some but not all statics.
-- @param #SPAWNSTATIC self
-- @param #string StaticShape Shape of the static, e.g. "carrier_tech_USA".
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitShape(StaticType)
  self.InitStaticShape=StaticType
  return self
end

--- Initialize name prefix statics get. This will be appended by "#0001", "#0002" etc. 
-- @param #SPAWNSTATIC self
-- @param #string NamePrefix Name prefix of statics spawned. Will append #0001, etc to the name.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitNamePrefix(NamePrefix)
  self.SpawnTemplatePrefix=NamePrefix
  return self
end

--- Init link to a unit.
-- @param #SPAWNSTATIC self
-- @param Wrapper.Unit#UNIT Unit The unit to which the static is linked.
-- @param #number OffsetX Offset in X.
-- @param #number OffsetY Offset in Y.
-- @param #number OffsetAngle Offset angle in degrees.
-- @return #SPAWNSTATIC self
function SPAWNSTATIC:InitLinkToUnit(Unit, OffsetX, OffsetY, OffsetAngle)

  self.InitLinkUnit=Unit
  self.InitOffsetX=OffsetX or 0
  self.InitOffsetY=OffsetX or 0
  self.InitOffsetAngle=OffsetAngle or 0

  return self
end

--- Spawn a new STATIC object.
-- @param #SPAWNSTATIC self
-- @param #number Heading (Optional) The heading of the static, which is a number in degrees from 0 to 360. Default is the heading of the template.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:Spawn( Heading, NewName ) --R2.3


  return self:_SpawnStatic(self.TemplateStaticUnit, self.CountryID)
  
  --[[
  local StaticTemplate, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate( self.SpawnTemplatePrefix )
  
  if StaticTemplate then
  
    local StaticUnitTemplate = StaticTemplate.units[1]
  
    StaticTemplate.name = NewName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex )
    
    StaticTemplate.heading=Heading and math.rad(Heading) or StaticTemplate.heading
        
    _DATABASE:_RegisterStaticTemplate( StaticTemplate, CoalitionID, CategoryID, CountryID )

    local Static = coalition.addStaticObject( self.CountryID or CountryID, StaticTemplate.units[1] )
    
    self.SpawnIndex = self.SpawnIndex + 1
  
    return _DATABASE:FindStatic(Static:getName())
  end
  
  return nil
  ]]
end

--- Creates a new @{Static} from a POINT_VEC2.
-- @param #SPAWNSTATIC self
-- @param Core.Point#POINT_VEC2 PointVec2 The 2D coordinate where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string NewName (Optional) The name of the new static.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:SpawnFromPointVec2(PointVec2, Heading, NewName)
  self:F( { PointVec2, Heading, NewName  } )
  
  local StaticTemplate, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate( self.SpawnTemplatePrefix )
  
  if StaticTemplate then
  
    local StaticUnitTemplate = StaticTemplate.units[1]
  
    StaticUnitTemplate.x = PointVec2.x
    StaticUnitTemplate.y = PointVec2.z
  
    StaticTemplate.route = nil
    StaticTemplate.groupId = nil
    
    StaticTemplate.name = NewName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex )
    StaticUnitTemplate.name = StaticTemplate.name
    StaticUnitTemplate.heading = ( Heading / 180 ) * math.pi
    
    _DATABASE:_RegisterStaticTemplate( StaticTemplate, CoalitionID, CategoryID, CountryID)
    
    self:F({StaticTemplate = StaticTemplate})

    local Static = coalition.addStaticObject( self.CountryID or CountryID, StaticTemplate.units[1] )
    
    self.SpawnIndex = self.SpawnIndex + 1
    
    return _DATABASE:FindStatic(Static:getName())
  end
  
  return nil
end


--- Creates a new @{Static} from a COORDINATE.
-- @param #SPAWNSTATIC self
-- @param Core.Point#COORDINATE Coordinate The 3D coordinate where to spawn the static.
-- @param #number Heading (Optional) Heading The heading of the static, which is a number in degrees from 0 to 360. Default is 0 degrees.
-- @param #string NewName (Optional) The name of the new static.
-- @return Wrapper.Static#STATIC The spawned STATIC object.
function SPAWNSTATIC:SpawnFromCoordinate(Coordinate, Heading, NewName)

  -- Set up coordinate.
  self.InitStaticCoordinate=Coordinate
  
  if Heading then
    self.InitStaticHeading=Heading
  end
  
  if NewName then
    self.InitStaticName=NewName
  end

  return self:_SpawnStatic(self.TemplateStaticUnit, self.CountryID)

  --[[
  
  local StaticTemplate, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate( self.SpawnTemplatePrefix )
  
  if StaticTemplate then
  
    Heading=Heading or 0
  
    local StaticUnitTemplate = StaticTemplate.units[1]
  
    StaticUnitTemplate.x   = Coordinate.x    
    StaticUnitTemplate.y   = Coordinate.z
    StaticUnitTemplate.alt = Coordinate.y
  
    StaticTemplate.route = nil
    StaticTemplate.groupId = nil
    
    StaticTemplate.name = NewName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex )
    StaticUnitTemplate.name = StaticTemplate.name
    StaticUnitTemplate.heading = ( Heading / 180 ) * math.pi
    
    _DATABASE:_RegisterStaticTemplate( StaticTemplate, CoalitionID, CategoryID, CountryID)
    
    self:F({StaticTemplate = StaticTemplate})

    local Static = coalition.addStaticObject( self.CountryID or CountryID, StaticTemplate.units[1] )
    
    self.SpawnIndex = self.SpawnIndex + 1
    
    return _DATABASE:FindStatic(Static:getName())
  end
  
  return nil
  
  ]]
end


--- Creates a new @{Static} from a @{Zone}.
-- @param #SPAWNSTATIC self
-- @param Core.Zone#ZONE_BASE Zone The Zone where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @param #string NewName (optional) The name of the new static.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:SpawnFromZone(Zone, Heading, NewName)

  -- Spawn the new static at the center of the zone.
  local Static = self:SpawnFromPointVec2( Zone:GetPointVec2(), Heading, NewName )
  
  return Static
end

--- Spawns a new static using a given template. Additionally, the country ID needs to be specified, which also determines the coalition of the spawned static.
-- @param #SPAWNSTATIC self
-- @param #SPAWNSTATIC.TemplateData Template Spawn unit template.
-- @param #number CountryID The country ID.
-- @return Wrapper.Static#STATIC The static spawned.
function SPAWNSTATIC:_SpawnStatic(Template, CountryID)

  local CountryID=CountryID or self.CountryID
  
  if self.InitStaticCoordinate then  
    Template.x   = self.InitStaticCoordinate.x    
    Template.y   = self.InitStaticCoordinate.z
    Template.alt = self.InitStaticCoordinate.y  
  end
  
  if self.InitStaticHeading then
    Template.heading = math.rad(self.InitStaticHeading)  
  end
  
  if self.InitStaticLivery then
    Template.livery_id=self.InitStaticLivery
  end
  
  if self.InitDead~=nil then
    Template.dead=self.InitDead
  end
  
  if self.InitLinkUnit then
    Template.linkUnit=self.InitLinkUnit:GetID()
    Template.linkOffset=true
    Template.offsets={}
    Template.offsets.y=self.InitOffsetY
    Template.offsets.x=self.InitOffsetX
    Template.offsets.angle=self.InitOffsetAngle and math.rad(self.InitOffsetAngle) or 0
  end
  
  -- Name of the spawned static.
  Template.name = self.InitStaticName or string.format("%s#%05d", self.SpawnTemplatePrefix, self.SpawnIndex)

  -- Register the new static.
  --_DATABASE:_RegisterStaticTemplate(Template, self.CoalitionID, self.CategoryID, CountryID)
  
  -- Add static to the game.
  local Static=coalition.addStaticObject(CountryID, Template)
  
  -- Increase spawn index counter.
  self.SpawnIndex = self.SpawnIndex + 1
  
  return _DATABASE:FindStatic(Static:getName())
end

--- Respawns the original @{Static}.
-- @param #SPAWNSTATIC self
-- @param #number delay Delay before respawn in seconds.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:ReSpawn(delay)
  
  if delay and delay>0 then
    self:ScheduleOnce(delay, SPAWNSTATIC.ReSpawn, self)
  else  
  
    local StaticTemplate, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate( self.SpawnTemplatePrefix )
    
    if StaticTemplate then
  
      local StaticUnitTemplate = StaticTemplate.units[1]
      StaticTemplate.route = nil
      StaticTemplate.groupId = nil
      
      local Static = coalition.addStaticObject( self.CountryID or CountryID, StaticTemplate.units[1] )
      
      return _DATABASE:FindStatic(Static:getName())
    end
    
    return nil
  end
  
  return self
end


--- Creates the original @{Static} at a POINT_VEC2.
-- @param #SPAWNSTATIC self
-- @param Core.Point#COORDINATE Coordinate The 2D coordinate where to spawn the static.
-- @param #number Heading The heading of the static, which is a number in degrees from 0 to 360.
-- @return #SPAWNSTATIC
function SPAWNSTATIC:ReSpawnAt( Coordinate, Heading )
  
  local StaticTemplate, CoalitionID, CategoryID, CountryID = _DATABASE:GetStaticGroupTemplate( self.SpawnTemplatePrefix )
  
  if StaticTemplate then

    local StaticUnitTemplate = StaticTemplate.units[1]
  
    StaticUnitTemplate.x = Coordinate.x
    StaticUnitTemplate.y = Coordinate.z

    StaticUnitTemplate.heading = Heading and ( ( Heading / 180 ) * math.pi ) or StaticTemplate.heading
    
    local Static = coalition.addStaticObject( self.CountryID or CountryID, StaticTemplate.units[1] )
    
    return _DATABASE:FindStatic(Static:getName())
  end
  
  return nil
end

