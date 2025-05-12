local XUiGridCond = require("XUi/XUiSettleWinMainLine/XUiGridCond")
-- 超解
local XUiPanelExhibitionSuperInfo = XClass(nil, "XUiPanelExhibitionSuperInfo")
local XUiGridCondition = require("XUi/XUiExhibition/XUiGridCondition")
local ConditionDesNum = 3
local CanRing = nil

local GetAureoleIndexInListById = function (aureoleId, list)
    for k, v in pairs(list) do
        if v.Id == aureoleId then
            return k
        end
    end
end

function XUiPanelExhibitionSuperInfo:Ctor(ui, rootUi)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    self.RootUi = rootUi
    XTool.InitUiObject(self)

    XUiHelper.RegisterClickEvent(self, self.BtnOccupy, function ()  XDataCenter.FubenAwarenessManager.OpenUi() end)
    XUiHelper.RegisterClickEvent(self, self.BtnBreak, self.OnBtnBreakClick)
end

-- 摄像机对准终解环
function XUiPanelExhibitionSuperInfo:SetCameraToAureole(flag)
    if not self.Character then
        return
    end

    local root3dUi = self.RootUi.UiModelGo.transform
    local charaModel = self.RootUi.PanelRoleModel:GetChild(0) -- 拿到角色模型的对象 root:FindTransform
    
    local targetCamera = root3dUi:FindTransform("AureolenNearCamera")
    targetCamera.gameObject:SetActiveEx(flag)

    local rootName, _ = XDataCenter.FashionManager.GetFashionLiberationEffectRootAndPath(self.Character.FashionId) -- 获取该角色手环挂点名字
    local targetTrans = charaModel.transform:FindTransform(rootName) -- 拿到要对准的目标节点
    local targetTransPos = targetTrans.position
    
    local Vector3 = CS.UnityEngine.Vector3(targetTransPos.x + 0.12, targetTransPos.y, targetCamera.position.z)
    targetCamera.position = Vector3
end

-- 自定义终解环样式
function XUiPanelExhibitionSuperInfo:SetLiberationEffect(aureoleId)
    if not CanRing then
        return
    end

    if not self.Character then
        return
    end

    -- 刷新手环
    local rootName, _ = XDataCenter.FashionManager.GetFashionLiberationEffectRootAndPath(self.Character.FashionId) -- 获取该角色手环挂点名字
    local modelId = XMVCA.XCharacter:GetCharLiberationLevelModelId(self.CharacterId,  XEnumConst.CHARACTER.GrowUpLevel.Super)
    self.RootUi.RoleModelPanel:SetLiberationEffect(modelId, rootName, aureoleId, self.CharacterId)
end

-- exhibitionRewardConfig 是 ExhibitionReward.tab的数据 这个是share表
function XUiPanelExhibitionSuperInfo:Refresh(characterId, exhibitionRewardConfig)
    local character = XMVCA.XCharacter:GetCharacter(characterId)
    local levelId = exhibitionRewardConfig.LevelId
    local currLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(characterId, true)
    local isSuper = currLevel >= XEnumConst.CHARACTER.GrowUpLevel.Super
  
    self.CharacterId = characterId
    self.ExhibitionRewardConfig = exhibitionRewardConfig
    self.Character = character
    self.TxtTitle.text = XMVCA.XCharacter:GetCharLiberationLevelTitle(characterId, levelId)  -- 这个是拆出来的前端表，和实参里的config主键一样
    self.TxtDesc.text = XMVCA.XCharacter:GetCharLiberationLevelDesc(characterId, levelId) 

    local passed = true
    self.ConditionGrids = self.ConditionGrids or {}
    local conditionIds = exhibitionRewardConfig.ConditionIds
    for i = 1, ConditionDesNum do
        local conditionGrid = self.ConditionGrids[i]
        if not conditionGrid then
            conditionGrid = XUiGridCondition.New(self["GridCondition" .. i])
            self.ConditionGrids[i] = conditionGrid
        end

        local conditionId = conditionIds[i]
        local subPassed = conditionGrid:Refresh(conditionId, characterId)
        passed = passed and subPassed
    end

    -- 环
    local gridRing = self.GridRing
    if not gridRing then
        local uiObject = self.GridSupersolution
        gridRing = uiObject
        self.GridRing = gridRing
    end
    local currLiberateAureoleId = character.LiberateAureoleId
    local isAurole = XTool.IsNumberValid(XExhibitionConfigs.GetCharacterExhibitonLimitCfgByCharacterId(characterId).SetAureoleId)
    gridRing.gameObject:SetActiveEx(isAurole)
    CanRing = isAurole
    if isAurole then
        local allCurrCharaAureList = XExhibitionConfigs.GetAureoleListByCharacterId(characterId) -- 拿到该角色拥有的所有超解环列表
        local currIndex = 1
        if XTool.IsNumberValid(currLiberateAureoleId) then -- 如果设置过超解环
            currIndex = GetAureoleIndexInListById(currLiberateAureoleId, allCurrCharaAureList) or currIndex
        else -- 如果没设置过超解环，则展示默认时装的终解环
            local aureoleId = XFashionConfigs.GetFashionCfgById(character.FashionId).AureoleId
            local tempIndex = GetAureoleIndexInListById(aureoleId, allCurrCharaAureList)
            if tempIndex then
                currIndex = tempIndex
                currLiberateAureoleId = aureoleId
            end
        end
        gridRing:GetObject("RImgQiu"):SetRawImage(allCurrCharaAureList[currIndex].Icon)
        gridRing:GetObject("Red").gameObject:SetActiveEx(false)
        local btn = gridRing:GetObject("BtnReplace")
        btn:SetDisable(not isSuper)
        XUiHelper.RegisterClickEvent(self, btn, function () 
            -- 确认选择按钮回调
            local confirmCb = function (aureoleId) 
                local aureoleCfg = allCurrCharaAureList[currIndex]
                if aureoleId == aureoleCfg.Id then
                    return
                end

                local targetAureoleCfg = XFashionConfigs.GetAllConfigs(XFashionConfigs.TableKey.FashionAureole)[aureoleId]
                if not XTool.IsTableEmpty(targetAureoleCfg.Condition) then
                    for k, conditionId in pairs(targetAureoleCfg.Condition) do
                        local res, desc = XConditionManager.CheckCondition(conditionId, characterId)
                        if not res then
                            XUiManager.TipError(conditionId..desc)
                            return
                        end
                    end
                end

                XDataCenter.ExhibitionManager.CharacterSetLiberateAureoleIdRequest(characterId, aureoleId, function ()
                    self:Refresh(characterId, exhibitionRewardConfig)
                end)
            end
            -- 点击格子回调
            local selectCb = function (aureoleId)
                self:SetLiberationEffect(aureoleId)
            end
            local openCb = function ()
                self:SetCameraToAureole(true)
            end

            local closeCb = function ()
                self:SetCameraToAureole(false)
            end

            local title = CS.XTextManager.GetText("ExhibitionSelectAureoTitle")
            local desc = CS.XTextManager.GetText("ExhibitionSelectAureoDesc")
            self:OnBtnReplace(allCurrCharaAureList, currIndex, title, desc, confirmCb, selectCb, openCb, closeCb)
        end)
    end
    self:SetLiberationEffect(currLiberateAureoleId)

    -- 球
    local gridBall = self.GridBall
    if not gridBall then
        local uiGo = CS.UnityEngine.Object.Instantiate(self.GridSupersolution.transform, self.GridSupersolution.transform.parent)
        local uiObject = uiGo:GetComponent("UiObject")
        gridBall = uiObject
        self.GridBall = gridBall
    end
    local isBall = XTool.IsNumberValid(XExhibitionConfigs.GetCharacterExhibitonLimitCfgByCharacterId(characterId).SetBallColor)
    gridBall.gameObject:SetActiveEx(isBall)
    if isBall then
        local allBallList = {} -- 该角色的三种技能球对应的skillId
        local allSkillList = XMVCA.XCharacter:GetCharacterSkills(characterId)[1]
        local magicIdList = CS.XGame.Config:GetString("HigherLiberateLvMagicId")
        magicIdList = string.Split(magicIdList, "|")
        for i = 1, 3, 1 do
            local subSkillConfigDesc = allSkillList.subSkills[i].configDes
            allBallList[i] = {Id = tonumber(magicIdList[i]), Icon = subSkillConfigDesc.Icon}
        end
        local currIndex = XMVCA.XCharacter:CheckHasSuperExhibitionBallColor(characterId) or 1 -- 如果设置过超解球 拿到超解球的颜色
        gridBall:GetObject("RImgQiu"):SetRawImage(allBallList[currIndex].Icon)
        gridBall:GetObject("Red").gameObject:SetActiveEx(false)
        local btn = gridBall:GetObject("BtnReplace")
        btn:SetDisable(not isSuper)
        XUiHelper.RegisterClickEvent(self, btn, function ()
            local confirmCb = function (magicId)
                if magicId == allBallList[currIndex].Id then
                    return
                end
                XDataCenter.ExhibitionManager.CharacterSwitchLiberateMagicIdRequest(characterId, magicId, function ()
                    self.RootUi:UpdateView()
                end)
            end
            local title = CS.XTextManager.GetText("ExhibitionSelectBallColorTitle")
            local desc = CS.XTextManager.GetText("ExhibitionSelectBallColorDesc")

            local selectCb = function (id, gridIndex, uiAuroProxy)
                local templateTextNameGo = uiAuroProxy.TxtSkillName.gameObject
                local tempTextDescGo = uiAuroProxy.TxtSkillbrief.gameObject
                local tempParent = templateTextNameGo.transform.parent
                for i = 0, tempParent.childCount - 1 do
                    local child = tempParent:GetChild(i)
                    child.gameObject:SetActiveEx(false)
                end
                
                local subSkillConfigDesc = allSkillList.subSkills[gridIndex].configDes
                local titleStr = ""
                local descStr = ""
                
                uiAuroProxy.TxtSkillBallName.text = subSkillConfigDesc.Name
                for index, title in pairs(subSkillConfigDesc.Title) do
                    titleStr = title
                    descStr = subSkillConfigDesc.BriefDes[index]

                    local titleText = uiAuroProxy.TextTitleDic[index]
                    if not titleText then
                        titleText = CS.UnityEngine.Object.Instantiate(templateTextNameGo, uiAuroProxy.TxtSkillName.transform.parent)
                        uiAuroProxy.TextTitleDic[index] = titleText
                    end
                    titleStr = XUiHelper.ConvertLineBreakSymbol(titleStr)
                    titleText:GetComponent("Text").text = titleStr
                    titleText.gameObject:SetActiveEx(true)

                    local descText = uiAuroProxy.TextDescDic[index]
                    if not descText then
                        descText = CS.UnityEngine.Object.Instantiate(tempTextDescGo, uiAuroProxy.TxtSkillbrief.transform.parent)
                        uiAuroProxy.TextDescDic[index] = descText
                    end
                    descStr = XUiHelper.ConvertLineBreakSymbol(descStr)
                    descText:GetComponent("Text").text = descStr
                    descText.gameObject:SetActiveEx(true)
                end
            end

            self:OnBtnReplace(allBallList, currIndex, title, desc, confirmCb, selectCb)
        end)
    end
    -- 球和环都没有就隐藏奖励栏
    local isShowReward = isAurole or isBall 
    self.Title1.gameObject:SetActiveEx(isShowReward)

    -- 驻守按钮
    local curr = XDataCenter.FubenAwarenessManager.GetAllChapterOccupyNum()
    local total = #XDataCenter.FubenAwarenessManager.GetChapterIdList()

    local isCharaOccupy = XDataCenter.FubenAwarenessManager.CheckCharacterInOccupy(characterId)
    local isLeftOccupyPos = curr < total
    local isShowOccypy = isSuper and not isCharaOccupy and isLeftOccupyPos
    self.BtnOccupy.gameObject:SetActiveEx(isShowOccypy)

    -- 解放按钮
    local taskId = exhibitionRewardConfig.Id
    local taskFinished = XDataCenter.ExhibitionManager.CheckGrowUpTaskFinish(taskId)
    local canGetReward = passed and not taskFinished
    self.BtnBreak:SetDisable(not canGetReward, canGetReward)
    self.PanelAlreadyBreak.gameObject:SetActive(taskFinished)
    self.BtnBreak.gameObject:SetActive(not taskFinished)
end

function XUiPanelExhibitionSuperInfo:OnBtnBreakClick()
    -- 条件
    self.ConditionGrids = self.ConditionGrids or {}
    local conditionIds = self.ExhibitionRewardConfig.ConditionIds
    for i = 1, ConditionDesNum do
        local conditionId = conditionIds[i]
        if XTool.IsNumberValid(conditionId) then
            local res, desc = XConditionManager.CheckCondition(conditionId, self.CharacterId)
            if not res then
                XUiManager.TipError(desc)
                return
            end
        end
    end

    self.RootUi:OnBtnBreakClick()
end

function XUiPanelExhibitionSuperInfo:OnBtnReplace(list, currIndex, title, desc, confirmCb, onSelectCb, openCb, closeCb)
    local currLevel = XDataCenter.ExhibitionManager.GetCharacterGrowUpLevel(self.CharacterId, true)
    local isSuper = currLevel >= XEnumConst.CHARACTER.GrowUpLevel.Super
    if not isSuper then
        XUiManager.TipError(CS.XTextManager.GetText("ExhibitionSuperLimit"))
        return
    end
    if openCb then
        openCb()
    end
    XLuaUiManager.Open("UiExhibitionAureole", list, currIndex, title, desc, confirmCb, onSelectCb, closeCb)
end

function XUiPanelExhibitionSuperInfo:Show()
    self.GameObject:SetActive(true)
end

function XUiPanelExhibitionSuperInfo:Hide()
    self.GameObject:SetActive(false)
end

return XUiPanelExhibitionSuperInfo