local XPlanetIScene = require("XEntity/XPlanet/XGameObject/XPlanetIScene")
local XChapterPlanet = require("XEntity/XPlanet/XGameObject/XChapterPlanet")
local XPlanetRunningExplore = require("XUi/XUiPlanet/Explore/XPlanetRunningExplore")

---@class XPlanetMainScene:XPlanetIScene
local XPlanetMainScene = XClass(XPlanetIScene, "XPlanetMainScene")

function XPlanetMainScene:Ctor(root, stageId)
end


--region 相机轨道
function XPlanetMainScene:UpdateCameraInMain()
    if not self:CheckIsHaveCamera() then return end
    local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamMain())
    self:SetPlanetActive(true)
    self:SetSceneLiuXingEffect(false)
    self:HideChapterPlanet()
    self.LastPosition = false
    self._PlanetCamera:ChangeStaticModeByCamera(cam)
end

function XPlanetMainScene:UpdateCameraInHomeland(isAnim)
    if not self:CheckIsHaveCamera() then return end
    self:SetPlanetActive(true)
    self:SetSceneLiuXingEffect(false)
    self:HideChapterPlanet()
    self._PlanetCamera:ChangeFreeModeByCamera(isAnim)
end

function XPlanetMainScene:UpdateCameraInFollow()
    if not self:CheckIsHaveCamera() then return end
    if self._PlanetCamera:CheckIsInFollowMode() then
        self:UpdateCameraInHomeland()
    else
        local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamFollowRole())
        self._Explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.FOLLOW)
        self:SetCameraFollow(self._Explore:GetCaptainTransform(), cam, function()
            self._Explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.FOLLOW)
        end)
    end
end
--endregion


--region 章节
function XPlanetMainScene:UpdateCameraInChapter(cb)
    if not self:CheckIsHaveCamera() then return end
    local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamChapter())
    self:SetPlanetActive(false)
    self:ShowChapterPlanet()
    self:SetSceneLiuXingEffect(true)
    local inCenter = Vector3(-cam:GetPosition().x + XPlanetConfigs.GetCamChapterXOffset() / 2, 0, 0)
    local offset = self.LastPosition and self.LastPosition - cam:GetPosition() or inCenter
    self._PlanetCamera:ChangeStaticModeByCamera(cam, offset, nil, self.LastPosition, nil, cb)
    self.LastPosition = false
end

function XPlanetMainScene:UpdateCameraInChapterChoice(chapterId, beginCb, endCb)
    if not self:CheckIsHaveCamera() then return end
    local cam = XDataCenter.PlanetManager.GetCamera(XPlanetConfigs.GetCamStageChoose())
    self:SetPlanetActive(false)
    self:ShowChapterPlanet()
    self:SetSceneLiuXingEffect(true)
    local position = self._ChapterPlanet[chapterId].transform.position
    if not self.LastPosition then
        self.LastPosition = self._PlanetCamera:GetCameraTransform().localPosition
    end
    self:_SetChapterCamPosition(chapterId)
    self._PlanetCamera:ChangeStaticModeByCamera(cam, position, nil, true, beginCb, endCb)
end

function XPlanetMainScene:_SetChapterCamPosition(chapterId)
    if not self.LastPosition then
        return
    end
    local x = self._ChapterPlanet[chapterId].transform.position.x
    if chapterId == 1 then
        x = x + XPlanetConfigs.GetCamChapterXOffset() / 2
    end
    self.LastPosition = Vector3(x, self.LastPosition.y, self.LastPosition.z)
end

function XPlanetMainScene:HideChapterPlanet()
    for _, obj in pairs(self._ChapterAirEffectDir) do
        obj.gameObject:SetActiveEx(false)
    end
    for _, obj in pairs(self._ChapterPlanet) do
        obj.gameObject:SetActiveEx(false)
    end
    if XTool.UObjIsNil(self._AirEffect) then
        return
    end
    self._AirEffect.gameObject:SetActiveEx(true)
    self._AirEffect.localPosition = Vector3.zero
end

function XPlanetMainScene:ShowChapterPlanet()
    if XTool.IsTableEmpty(self._ChapterPlanet) then
        for chapterId, _ in pairs(self._ChapterAirEffectDir) do
            local go = XChapterPlanet.New(self._PlanetChapterAirEffectRoot, chapterId)
            go:Load(function()
                self._ChapterPlanet[chapterId] = go:GetGameObject()
            end)
        end
    end
    self:HideChapterPlanet()

    local offset = Vector3(XPlanetConfigs.GetCamChapterXOffset(), 0, 0)
    local showChapterList = XDataCenter.PlanetManager.GetShowChapterList()
    local _, playDir = XDataCenter.PlanetManager.CheckChapterUnlockRedPoint()
    for _, chapterId in ipairs(showChapterList) do
        self._ChapterAirEffectDir[chapterId].gameObject:SetActiveEx(true)
        self._ChapterAirEffectDir[chapterId].transform.localPosition = Vector3.zero + (chapterId - 1) * offset
        self._ChapterPlanet[chapterId].gameObject:SetActiveEx(true)
        self._ChapterPlanet[chapterId].transform.localPosition = Vector3.zero + (chapterId - 1) * offset
        self:RefreshChapterPlanetState(chapterId, playDir[chapterId])
    end
    self._AirEffect.gameObject:SetActiveEx(false)
end

function XPlanetMainScene:RefreshChapterPlanetState(chapterId, isBePlayUnLock)
    local obj = self._ChapterPlanet[chapterId]
    local planet = obj.gameObject:GetComponent("Planet")
    local viewModel = XDataCenter.PlanetManager.GetViewModel()
    local isUnlock = viewModel:CheckChapterIsUnlock(chapterId)
    local gray = XPlanetConfigs.GetChapterPlanetLockGray()
    local color = XUiHelper.Hexcolor2Color(XPlanetConfigs.GetChapterPlanetLockColorCode())
    planet:SetLock(not isUnlock or isBePlayUnLock, gray, color)
end

function XPlanetMainScene:PlayChapterPlanetUnlock(isLock, t)
    local _, playDir = XDataCenter.PlanetManager.CheckChapterUnlockRedPoint()
    local gray = XPlanetConfigs.GetChapterPlanetLockGray()
    local color = XUiHelper.Hexcolor2Color(XPlanetConfigs.GetChapterPlanetLockColorCode())
    local unlockColor = XUiHelper.Hexcolor2Color("FFFFFFFF")

    for chapterId, v in pairs(playDir) do
        local obj = self._ChapterPlanet[chapterId]
        local planet = obj.gameObject:GetComponent("Planet")
        planet:SetLock(isLock, gray - gray * t, CS.UnityEngine.Color.Lerp(color, unlockColor, t))
    end
end

function XPlanetMainScene:GetChapterPlanetPosition(chapterId)
    if self._ChapterPlanet[chapterId] then
        return self._ChapterPlanet[chapterId].transform.position
    end
    return Vector3.zero
end

function XPlanetMainScene:UpdatePlanetPosition(chapterId, position)
    if self._ChapterPlanet[chapterId] then
        self._ChapterPlanet[chapterId].transform.position = position
    end
end
--endregion


--region 星球Ui接口
function XPlanetMainScene:IsInMain()
    return XLuaUiManager.IsUiShow("UiPlanetMain")
end

local rotateSpeed = 57.29578 * 0.02    -- 旋转度
---主界面星球自转
---@param time number
function XPlanetMainScene:MainRotate(time)
    if not self:IsInMain() then
        return
    end
    self._PlanetCamera:GetTransform():RotateAround(self._PlanetCamera:GetTransform().position, self._MainRotateCross, rotateSpeed * time)
end

---初始化星球自转方向
function XPlanetMainScene:_InitMainRotateCross()
    local startTileId = self:GetRoadMapStartPoint()
    local nextTileId = self:GetNextRoadTileId(startTileId)
    local startLine = self:GetTileHeightPosition(startTileId) - self:GetPlanetPosition()
    local nextLine = self:GetTileHeightPosition(nextTileId) - self:GetPlanetPosition()
    self._MainRotateCross = Vector3.Cross(startLine, nextLine)
end

function XPlanetMainScene:OpenBuildDetail(tileId)
    if not self:CheckIsHavePlanet() then return end
    local build = self._Planet:GetBuildingByTileId(tileId)
    if XTool.IsTableEmpty(build) then return end
    XLuaUiManager.Open("UiPlanetBuildDetail", build:GetBuildingId(), true, false, build:GetGuid())
end

function XPlanetMainScene:GetBuildingCount(buildId)
    local result = 0
    if not self:CheckIsHavePlanet() then return result end
    local buildList = self._Planet:GetBuildingByBuildingId(buildId)
    if not XTool.IsTableEmpty(buildList) then result = #buildList end
    return result
end
--endregion


--region 星球改造
function XPlanetMainScene:RemoveCurBuilding()
    self:RemoveCurBuildingList()
    XEventManager.DispatchEvent(XEventId.EVENT_PLANET_RESUME_RUNNING, XPlanetExploreConfigs.PAUSE_REASON.BUILD)
end

---更新建筑
function XPlanetMainScene:UpdateBuilding(buildGuid, floorId)
    if not self:CheckIsHavePlanet() then return end
    local build = self._Planet:GetBuildingByBuildGuid(buildGuid)
    if XTool.IsTableEmpty(build) then return end
    if build:GetFloorId() == floorId then
        return
    end
    build:SetFloorId(floorId)
    local buildingList = {}
    table.insert(buildingList, build)
    XDataCenter.PlanetManager.RequestTalentUpdateBuild(buildingList, function()
        self._Planet:UpdateBuildTile(build)
    end)
end

---清空建筑
function XPlanetMainScene:ClearBuilding()
    if not self:CheckIsHavePlanet() then return end
    self._Planet:ClearTalentBuilding()
end

function XPlanetMainScene:UpdateRefromBuild()
    self._Planet:UpdateRefromBuild()
end

---更新地块
function XPlanetMainScene:UpdateFloor()
    if not self:CheckIsHavePlanet() then return end
end

---更新天气
function XPlanetMainScene:UpdateWeather()
    if not self:CheckIsHavePlanet() then return end
end

---更新角色
function XPlanetMainScene:UpdateCharacter()
    if not self:CheckIsHavePlanet() then return end
end
--endregion


--region 场景加载
function XPlanetMainScene:Release()
    self.Super.Release(self)
    self:RemoveTalentTeamUpdateEvent()
    if self._Explore then
        self._Explore:Destroy()
        self._Explore = nil
    end
    self._ChapterPlanet = {}
end

function XPlanetMainScene:InitAfterLoad()
    self:RegisterUiEventListener(handler(self, self.OnClick), XPlanetConfigs.SceneUiEventType.OnClick)
    --self:ClearUiEventListener()
    self:InitTalentTeamObj()
    self:AddTalentTeamUpdateEvent()
    self:SetSceneStarEffect()
end

function XPlanetMainScene:SetActive(active)
    if not self:Exist() then return end
    if active then
        if not self._Planet._GameObject.activeInHierarchy then
            self:SetPlanetActive(active)
        else
            self:TalentTeamResume()
        end
    else
        self:TalentTeamPause()
    end
    self._GameObject:SetActiveEx(active)
end

function XPlanetMainScene:SetPlanetActive(active)
    self._Planet._GameObject:SetActiveEx(active)
    self._PlanetAirEffectRoot.gameObject:SetActiveEx(active)
    if active then
        self:TalentTeamResume()
    else
        self:TalentTeamPause()
    end
end

function XPlanetMainScene:GetAssetPath()
    return XPlanetConfigs.GetMainSceneUrl()
end

function XPlanetMainScene:GetObjName()
    return "PlanetMainScene"
end
--endregion


--region 场景对象
function XPlanetMainScene:InitAirEffect()
    self._PlanetAirEffectRoot = self._Transform:Find("GroupBase/PlanetAirEffectRoot")
    if XTool.UObjIsNil(self._PlanetAirEffectRoot) then
        return
    end
    self._AirEffectDir = {}
    self._ChapterAirEffectDir = {}
    self._ChapterPlanet = {}
    for i = 0, self._PlanetAirEffectRoot.childCount - 1 do
        self._PlanetAirEffectRoot:GetChild(i).gameObject:SetActiveEx(false)
    end
    --章节大气节点初始化
    if XTool.UObjIsNil(self._PlanetChapterAirEffectRoot) then
        self._PlanetChapterAirEffectRoot = self._Transform:Find("GroupBase/PlanetChapterAirEffectRoot")
    end
    for i = 0, self._PlanetChapterAirEffectRoot.childCount - 1 do
        self._PlanetChapterAirEffectRoot:GetChild(i).gameObject:SetActiveEx(false)
    end
    --星球、大气Dir初始化
    for _, chapterId in ipairs(XPlanetStageConfigs.GetChapterIdList()) do
        local nodeName = XPlanetConfigs.GetMainAirEffectNodeName(chapterId)
        local effectObj = self._PlanetAirEffectRoot:Find(nodeName)
        if not XTool.UObjIsNil(effectObj) then
            self._AirEffectDir[chapterId] = effectObj
            self._ChapterAirEffectDir[chapterId] = self._PlanetChapterAirEffectRoot:Find(nodeName .. "Chapter")
            local go = XChapterPlanet.New(self._PlanetChapterAirEffectRoot, chapterId)
            go:Load(function()
                self._ChapterPlanet[chapterId] = go:GetGameObject()
            end)
        end
    end
    self._AirEffect = self._AirEffectDir[XPlanetConfigs.GetMainAirEffectChapterUse()]
    if XTool.UObjIsNil(self._AirEffect) then
        return
    end
    self._AirEffect.gameObject:SetActiveEx(true)
    self._AirEffect.localPosition = Vector3.zero
end

---流星场景特效(章节选择界面开启)
function XPlanetMainScene:SetSceneLiuXingEffect(active)
    if self._EffectLiuXing then
        local centerIndex = #self._ChapterPlanet / 2
        local position
        if centerIndex > math.floor(centerIndex) then
            position = self._ChapterPlanet[math.floor(centerIndex) + 1].transform.position
        elseif centerIndex == math.floor(centerIndex) then
            position = (self._ChapterPlanet[centerIndex].transform.position + self._ChapterPlanet[centerIndex + 1].transform.position) / 2
        else
            position = Vector3.zero
        end
        self._EffectLiuXing.gameObject:SetActiveEx(active)
        self._EffectLiuXing:SetParent(self._PlanetChapterAirEffectRoot, false)
        self._EffectLiuXing.transform.position = position + XPlanetConfigs.GetPositionByKey("SceneLiuxingEffectOffset")
        self._EffectLiuXing.transform.rotation = CS.UnityEngine.Quaternion.identity
    end
end

function XPlanetMainScene:SetSceneStarEffect()
    if not self._EffectStar then
        self._EffectStar = self._GroupParticle.gameObject:FindTransform("FxScene02304Star (1)")
    end
    if self._EffectStar then
        self._EffectStar.transform.localPosition = XPlanetConfigs.GetPositionByKey("MainStarEffectOffset")
        self._EffectStar.transform.localRotation = XPlanetConfigs.GetRotationByKey("MainStarEffectRotation")
        self._EffectStar.transform.localScale = XPlanetConfigs.GetPositionByKey("MainStarEffectScale")
    end
end
--endregion


--region 场景角色
function XPlanetMainScene:InitTalentTeamObj()
    ---@type XPlanetRunningExplore
    self._Explore = XPlanetRunningExplore.New()
    local data = {
        CharacterData = XDataCenter.PlanetManager.GetTeam():GetCharacterData(),
        MonsterData = {}
    }
    self._Explore:SetData(data)
    self._Explore:SetScene(self)
    self._Explore:StartSync()
    self._Explore:Pause()
    self._Timer = nil
    self:_InitMainRotateCross()
    if not self._Timer then
        self._Timer = XScheduleManager.ScheduleForever(function()
            if not self:Exist() then
                self:ReleaseTalentTeamObj()
                return
            end
            self._Explore:Update(CS.UnityEngine.Time.deltaTime * 1)
            if self._PlanetCamera then
                self:CameraUpdate(self._Explore, CS.UnityEngine.Time.deltaTime * 1)
            end
            self:MainRotate(CS.UnityEngine.Time.deltaTime)
        end, 0)
    end
    self:TalentTeamResume()
end

function XPlanetMainScene:ReleaseTalentTeamObj()
    if self._Timer then
        XScheduleManager.UnSchedule(self._Timer)
    end
    self._Timer = nil
end

function XPlanetMainScene:ResetTeam()
    if self._Explore and self._GameObject.activeInHierarchy then
        self._Explore:ResetLeaderPosition()
    end
end

function XPlanetMainScene:TalentTeamPause()
    if not self._Explore then
        return
    end
    if self._Explore:IsRunning() and self._GameObject.activeInHierarchy then
        self._Explore:Pause(XPlanetExploreConfigs.PAUSE_REASON.TALENT)
    end
end

function XPlanetMainScene:TalentTeamResume()
    if not self._Explore then
        return
    end
    if not self._Explore:IsRunning() and self._GameObject.activeInHierarchy then
        self._Explore:Resume(XPlanetExploreConfigs.PAUSE_REASON.TALENT)
    end
end

function XPlanetMainScene:OnTalentTeamUpdate()
    if not self._Explore then
        return
    end
    local characterIdList = XDataCenter.PlanetManager.GetTeam():GetCharacterIdList()
    self._Explore:UpdateTeam(characterIdList)
end

function XPlanetMainScene:AddTalentTeamUpdateEvent()
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_PAUSE_RUNNING, self.TalentTeamPause, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_RESUME_RUNNING, self.TalentTeamResume, self)
    XEventManager.AddEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_TEAM, self.OnTalentTeamUpdate, self)
end

function XPlanetMainScene:RemoveTalentTeamUpdateEvent()
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_PAUSE_RUNNING, self.TalentTeamPause, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_RESUME_RUNNING, self.TalentTeamResume, self)
    XEventManager.RemoveEventListener(XEventId.EVENT_PLANET_UPDATE_REFROM_TEAM, self.OnTalentTeamUpdate, self)
end
--endregion


--region 场景交互
function XPlanetMainScene:RegisterObjClick(func)
    self._ObjClickFunc = func
end

function XPlanetMainScene:OnClick()
    if not self:CheckIsInNoneMode() then
        return
    end
    local hit = self._PlanetCamera:RayCast()
    if XTool.UObjIsNil(hit) then return end
    local tile = hit:GetComponent(typeof(CS.Planet.PlanetTile))
    if XTool.UObjIsNil(tile) then return end

    local tileId = tile.TileId
    if not self:CheckTileIsHaveBuild(tileId) then
        return
    end

    --回收建筑
    local isQuickBuild = XDataCenter.PlanetManager.GetReformQuickRecycleMode() and XLuaUiManager.IsUiLoad("UiPlanetRemould")
    if isQuickBuild then
        self._PlanetCamera:FreeModeLookAt(tile.transform.position)
        if self:CheckTileIsDefaultBuild(tileId) then
            XUiManager.TipErrorWithKey("PlanetRunningNoCycle")
            return    
        end
        self:DeleteBuildingByTileId(tileId)
        return
    end

    if self:CheckTileIsDefaultBuild(tileId) then
        self._PlanetCamera:FreeModeLookAt(tile.transform.position)
        local tileData = self._Planet:GetTileData(tileId)
        if XTool.IsTableEmpty(tileData) then return end
        XLuaUiManager.Open("UiPlanetBuildDetail", tileData:GetBuildingId(), true, false, nil, nil, true)
        return
    end

    --打开建筑详情
    if self:CheckTileIsHaveBuild(tileId) then
        self._PlanetCamera:FreeModeLookAt(tile.transform.position)
        self:OpenBuildDetail(tileId)
    end
end
--endregion

function XPlanetIScene:_InitTopNode()
    self._TopNode = self._Transform:Find("GroupBase/TopNode")
    local PlanetTopNode = self._TopNode.gameObject:GetComponent(typeof(CS.PlanetTopNode))
    PlanetTopNode.CameraNode = self._PlanetCamera:GetCameraTransform()
    PlanetTopNode.PlanetNode = self._Planet:GetTransform()
end

return XPlanetMainScene