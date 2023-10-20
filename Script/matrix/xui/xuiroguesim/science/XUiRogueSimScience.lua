-- 科技数
---@class XUiRogueSimScience : XLuaUi
---@field private _Control XRogueSimControl
local XUiRogueSimScience = XLuaUiManager.Register(XLuaUi, "UiRogueSimScience")

function XUiRogueSimScience:OnAwake()
    self.GridScience.gameObject:SetActiveEx(false)
    self.PanelScienceDetail.gameObject:SetActiveEx(false)

    self.DefaultSelTechId = 1       -- 默认选中的科技Id
    self.TechLv = 0                 -- 科技树等级
    self.NormalScienceDic = {}      -- 普通科技列表
    self.SelectTechId = nil         -- 当前选中科技Id
    self.SelScienceUiObj = nil      -- 当前选中科技预制体

    self.LevelSciencesDic = {}
    self.LevelMaxUnlock = 0         -- 关键科技最高解锁等级
    self.LevelMaxActive = 0         -- 关键科技最高激活等级

    self.TechLvToMainLvDic = self:GetTechLvToMainLvDic()
    self:RegisterUiEvents()
end

function XUiRogueSimScience:OnStart()
    self:InitTechLv()
    self:InitNormalScience()
    self:InitLevelScience()
end

function XUiRogueSimScience:OnEnable()
    self.TechLv = self._Control:GetCurTechLv()
    self:Refresh()
    self:SelectDefaultScience()
end

function XUiRogueSimScience:OnGetLuaEvents()
    return {
        XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE,
    }
end

function XUiRogueSimScience:OnNotify(event, ...)
    if event == XEventId.EVENT_ROGUE_SIM_RESOURCE_CHANGE then
        self:RefreshAsset()
    end
end

function XUiRogueSimScience:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnBack, self.OnBtnBackClick)
    XUiHelper.RegisterClickEvent(self, self.BtnMainUi, self.OnBtnMainUiClick)
    XUiHelper.RegisterClickEvent(self, self.PanelScienceDetail:GetObject("BtnUnlock"), self.OnBtnUnlockClick)
end

function XUiRogueSimScience:OnBtnBackClick()
    self:Close()
end

function XUiRogueSimScience:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiRogueSimScience:OnBtnUnlockClick()
    -- 未解锁
    local isUnLock, tips = self:IsNormalTechUnlock(self.SelectTechId)
    if not isUnLock then
        XUiManager.TipError(tips)
        return
    end

    -- 金币不够升级
    if not self.IsGoldEnough then
        local tips = self._Control:GetClientConfig("TechGoldUnlockTips")
        XUiManager.TipError(tips)
        return
    end

    self._Control:RogueSimUnlockTechRequest(self.SelectTechId, function()
        self:RefreshNormalScience()
        self:RefreshNormalDetail(self.SelectTechId)
    end)
end

function XUiRogueSimScience:OnNormalTechClick(techId)
    if self.SelScienceUiObj then
        self.SelScienceUiObj:GetObject("Select").gameObject:SetActiveEx(false)
    end
    local science = self.NormalScienceDic[techId]
    local uiObj = science.UiObj
    uiObj:GetObject("Select").gameObject:SetActiveEx(true)
    self.PanelScienceDetail.gameObject:SetActiveEx(true)
    self:RefreshNormalDetail(techId)

    self.SelScienceUiObj = uiObj
    self.SelectTechId = techId
end

function XUiRogueSimScience:OnLevelTechClick(techLv, index, uiObj)
    -- 科技树等级不足
    if self.TechLv < techLv then
        local mainLv = self.TechLvToMainLvDic[techLv]
        local tips = string.format(self._Control:GetClientConfig("TechLevelUnlockTips"), mainLv)
        XUiManager.TipError(tips)
        return
    end

    -- 前置科技未点亮
    if self.LevelMaxUnlock < techLv then
        local tips = self._Control:GetClientConfig("TechPreUnlockTips")
        XUiManager.TipError(tips)
        return
    end

    local techData = self._Control:GetTechData()
    local levelData = techData.LevelData[techLv]
    local techId = levelData and levelData.KeyTechs[index] or nil
    local isUnlock = self.LevelMaxUnlock >= techLv
    local isActive = self.LevelMaxActive >= techLv and techId ~= nil
    if not isActive then
        XLuaUiManager.Open("UiRogueSimChooseScience", techLv, isUnlock, function()
            self:Refresh()
            self:OnLevelTechClick(techLv, index, uiObj)
        end)
    else
        if self.SelScienceUiObj then
            self.SelScienceUiObj:GetObject("Select").gameObject:SetActiveEx(false)
        end
        uiObj:GetObject("Select").gameObject:SetActiveEx(true)
        self:RefreshLevelDetail(techId)
        self.SelScienceUiObj = uiObj
        self.SelectTechId = techId
    end
end

-- 选中默认普通科技
function XUiRogueSimScience:SelectDefaultScience()
    self:OnNormalTechClick(self.DefaultSelTechId)
end

function XUiRogueSimScience:Refresh()
    self.LevelMaxUnlock = self:GetLevelMaxUnlock()
    self.LevelMaxActive = self:GetLevelMaxActive()

    self:RefreshNormalScience()
    self:RefreshLevelScience()
    self:RefreshAsset()
end

-- 初始化普通科技
function XUiRogueSimScience:InitNormalScience()
    local techCfgs = self._Control:GetRogueSimTechConfigs()

    -- 普通科技
    local normalTechCfgs = {}
    for _, techCfg in pairs(techCfgs) do
        if techCfg.TechType == XEnumConst.RogueSim.TechType.Normal then
            table.insert(normalTechCfgs, techCfg)
        end
    end
    self.DefaultSelTechId = normalTechCfgs[1].Id

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, techCfg in ipairs(normalTechCfgs) do
        local parentGo = self.PanelNormalScience:GetObject("Science"..tostring(i))
        local line = parentGo:Find("Line")
        if line then
            line.gameObject:SetActiveEx(false)
        end
        local line2 = parentGo:Find("Line2")
        if line2 then
            line2.gameObject:SetActiveEx(true)
        end

        local uiObj = CSInstantiate(self.GridScience, parentGo)
        uiObj.gameObject:SetActiveEx(true)
        self:SetUiSprite(uiObj:GetObject("ImgScience"), techCfg.Icon)
        uiObj:GetObject("Mask").gameObject:SetActiveEx(true)
        uiObj:GetObject("ImgLock").gameObject:SetActiveEx(true)
        uiObj:GetObject("Select").gameObject:SetActiveEx(false)
        local techId = techCfg.Id
        uiObj:GetObject("BtnScience").CallBack = function()
            self:OnNormalTechClick(techId)
        end

        self.NormalScienceDic[techCfg.Id] = {Id = techCfg.Id, UiObj = uiObj, Line = line, Line2 = line2}
    end
end

-- 普通科技是否解锁
function XUiRogueSimScience:IsNormalTechUnlock(techId)
    local techCfg = self._Control:GetRogueSimTechConfig(techId)

    -- 已激活
    if self.ActiveNormalIdDic[techId] then
        return true
    end

    -- 科技树等级
    if self.TechLv < techCfg.Level then
        local mainLv = self.TechLvToMainLvDic[techCfg.Level]
        local tips = string.format(self._Control:GetClientConfig("TechLevelUnlockTips"), mainLv)
        return false, tips
    end

    -- 关键科技
    local techData = self._Control:GetTechData()
    local techLevelCfg = self._Control:GetRogueSimTechLevelConfig(techCfg.Level)
    local techLevelData = techData.LevelData[techCfg.Level]
    if techLevelCfg.Num > 0 and (not techLevelData or #techLevelData.KeyTechs == 0) then
        return false, self._Control:GetClientConfig("TechPreLevelUnlockTips")
    end

    -- 前置科技
    for _, preId in ipairs(techCfg.PreIds) do
        if not self.ActiveNormalIdDic[preId] then
            return false, self._Control:GetClientConfig("TechPreUnlockTips")
        end
    end

    return true
end

-- 刷新普通科技
function XUiRogueSimScience:RefreshNormalScience()
    local techData = self._Control:GetTechData()
    self.ActiveNormalIdDic = {}
    for _, techId in ipairs(techData.NormalTechs) do
        self.ActiveNormalIdDic[techId] = true
    end

    for techId, science in ipairs(self.NormalScienceDic) do
        local isActive = self.ActiveNormalIdDic[techId] == true
        local isUnLock = self:IsNormalTechUnlock(techId)
        science.UiObj:GetObject("Mask").gameObject:SetActiveEx(not isActive)
        science.UiObj:GetObject("ImgLock").gameObject:SetActiveEx(not isUnLock)
        if science.Line then
            science.Line.gameObject:SetActiveEx(isActive)
        end
        if science.Line2 then
            science.Line2.gameObject:SetActiveEx(not isActive)
        end
    end
end

-- 刷新普通科技的详情
function XUiRogueSimScience:RefreshNormalDetail(techId)
    local techCfg = self._Control:GetRogueSimTechConfig(techId)
    local uiObj = self.PanelScienceDetail
    local scienceUiObj = uiObj:GetObject("GridScience")
    local isUnLock, tips = self:IsNormalTechUnlock(techId)
    local isActive = self.ActiveNormalIdDic[techId] == true

    self:SetUiSprite(scienceUiObj:GetObject("ImgScience"), techCfg.Icon)
    scienceUiObj:GetObject("PanelLock").gameObject:SetActiveEx(not isUnLock)
    uiObj:GetObject("TxtName").text = techCfg.Name
    uiObj:GetObject("TxtDetails").text = techCfg.Desc

    -- 刷新前置科技
    local showPreTech = #techCfg.PreIds > 0
    uiObj:GetObject("PanelPreScience").gameObject:SetActiveEx(showPreTech)
    if showPreTech then
        local cloneGrid = uiObj:GetObject("GridPreScience")
        local parentGo = uiObj:GetObject("PreScienceList")

        self.PreSciences = self.PreSciences or {cloneGrid}
        for _, science in ipairs(self.PreSciences) do
            science.gameObject:SetActiveEx(false)
        end

        local CSInstantiate = CS.UnityEngine.Object.Instantiate
        for i, preId in ipairs(techCfg.PreIds) do
            local science = self.PreSciences[i]
            if not science then
                science = CSInstantiate(cloneGrid, parentGo)
                table.insert(self.PreSciences, science)
            end
            science.gameObject:SetActiveEx(true)

            local preTechCfg = self._Control:GetRogueSimTechConfig(preId)
            local isPreActive = self.ActiveNormalIdDic[preId] == true
            self:SetUiSprite(science:GetObject("ImgScience"), preTechCfg.Icon)
            science:GetObject("PanelLock").gameObject:SetActiveEx(not isPreActive)

            local tempPreTechId = preId
            science:GetObject("Button").CallBack = function()
                self:OnNormalTechClick(tempPreTechId)
            end
        end
    end

    -- 解锁条件
    local txtCondition = uiObj:GetObject("TxtCondition")
    txtCondition.gameObject:SetActiveEx(not isUnLock)
    if not isUnLock then
        txtCondition.text = tips
    end

    -- 激活消耗
    uiObj:GetObject("PanelConsume").gameObject:SetActiveEx(not isActive and isUnLock)
    uiObj:GetObject("BtnUnlock").gameObject:SetActiveEx(not isActive and isUnLock)
    if not isActive and isUnLock then
        local const = techCfg.Cost
        local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
        self.IsGoldEnough = own >= const
        local consume = uiObj:GetObject("PanelConsume")
        local consumeOn = consume:GetObject("ConsumeOn")
        local consumeOff = consume:GetObject("ConsumeOff")
        consumeOn.gameObject:SetActiveEx(self.IsGoldEnough)
        consumeOff.gameObject:SetActiveEx(not self.IsGoldEnough)
        local showUiObj = self.IsGoldEnough and consumeOn or consumeOff
        
        local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
        showUiObj:GetObject("Icon"):SetRawImage(icon)
        local discountPrice = self._Control:GetTechDiscountPrice(const)
        showUiObj:GetObject("TxtCosumeNumber").text = tostring(discountPrice)
    end
end

-- 初始化关键科技
function XUiRogueSimScience:InitLevelScience()
    local levelCfgs = self._Control:GetRogueSimTechLevelConfigs()

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local index = 1
    for lv, levelCfg in ipairs(levelCfgs) do
        for i = 1, levelCfg.Num do
            local parentGo = self.PanelKeyScience:GetObject("Science"..tostring(index))
            local line = parentGo:Find("Line")
            local line2 = parentGo:Find("Line2")
            if line then
                line.gameObject:SetActiveEx(false)
            end
            if line2 then
                line2.gameObject:SetActiveEx(true)
            end

            local uiObj = CSInstantiate(self.GridKeyScience, parentGo)
            uiObj.gameObject:SetActiveEx(true)
            uiObj:GetObject("ImgScience").gameObject:SetActiveEx(false)
            uiObj:GetObject("Mask").gameObject:SetActiveEx(true)
            uiObj:GetObject("ImgLock").gameObject:SetActiveEx(true)
            uiObj:GetObject("Select").gameObject:SetActiveEx(false)

            local sciences = self.LevelSciencesDic[lv]
            if sciences == nil then
                sciences = {}
                self.LevelSciencesDic[lv] = sciences
            end
            table.insert(sciences, {UiObj = uiObj, Line = line, Line2 = line2})

            local techLv = lv
            local lvIndex = i
            uiObj:GetObject("BtnScience").CallBack = function()
                self:OnLevelTechClick(techLv, lvIndex, uiObj)
            end

            index = index + 1
        end
    end
end

-- 刷新关键科技
function XUiRogueSimScience:RefreshLevelScience()
    local techData = self._Control:GetTechData()
    local levelCfgs = self._Control:GetRogueSimTechLevelConfigs()

    -- 刷新已解锁
    for lv, levelCfg in ipairs(levelCfgs) do
        if levelCfg.Num ~= 0 and self.LevelMaxUnlock >= lv then
            local sciences = self.LevelSciencesDic[lv]
            for i, science in ipairs(sciences) do
                science.UiObj:GetObject("ImgLock").gameObject:SetActiveEx(false)
            end
        end
    end

    -- 刷新已激活
    for lv, levelData in pairs(techData.LevelData) do
        local sciences = self.LevelSciencesDic[lv]
        for i, techId in ipairs(levelData.KeyTechs) do
            local uiObj = sciences[i].UiObj
            local techCfg = self._Control:GetRogueSimTechConfig(techId)
            self:SetUiSprite(uiObj:GetObject("ImgScience"), techCfg.Icon)
            uiObj:GetObject("ImgScience").gameObject:SetActiveEx(true)
            uiObj:GetObject("Mask").gameObject:SetActiveEx(false)
            uiObj:GetObject("ImgLock").gameObject:SetActiveEx(false)
            if sciences[i].Line then
                sciences[i].Line.gameObject:SetActiveEx(true)
            end
            if sciences[i].Line2 then
                sciences[i].Line2.gameObject:SetActiveEx(false)
            end
        end
    end
end

-- 关键科技详情
function XUiRogueSimScience:RefreshLevelDetail(techId)
    local techCfg = self._Control:GetRogueSimTechConfig(techId)
    local uiObj = self.PanelScienceDetail

    local scienceUiObj = uiObj:GetObject("GridScience")
    local isUnLock = self:IsNormalTechUnlock(techId)
    self:SetUiSprite(scienceUiObj:GetObject("ImgScience"), techCfg.Icon)
    scienceUiObj:GetObject("PanelLock").gameObject:SetActiveEx(false)

    uiObj:GetObject("TxtName").text = techCfg.Name
    uiObj:GetObject("TxtDetails").text = techCfg.Desc

    uiObj:GetObject("PanelPreScience").gameObject:SetActiveEx(false)
    uiObj:GetObject("PanelConsume").gameObject:SetActiveEx(false)
    uiObj:GetObject("BtnUnlock").gameObject:SetActiveEx(false)
    uiObj:GetObject("TxtCondition").gameObject:SetActiveEx(false)
end

function XUiRogueSimScience:RefreshAsset()
    local icon = self._Control.ResourceSubControl:GetResourceIcon(XEnumConst.RogueSim.ResourceId.Gold)
    local own = self._Control.ResourceSubControl:GetResourceOwnCount(XEnumConst.RogueSim.ResourceId.Gold)
    self.PanelSpecialTool:GetObject("RImgSpecialTool3"):SetRawImage(icon)
    self.PanelSpecialTool:GetObject("TxtSpecialTool3").text = tostring(own)
end

-- 获取关键科技解锁的最高等级
function XUiRogueSimScience:GetLevelMaxUnlock()
    local levelCfgs = self._Control:GetRogueSimTechLevelConfigs()
    local levelMaxActive = self:GetLevelMaxActive()

    local levelMaxUnlock = 0
    for lv, levelCfg in ipairs(levelCfgs) do
        if lv <= self.TechLv and lv <= levelMaxActive then
            levelMaxUnlock = lv
        end
    end

    return levelMaxUnlock
end

-- 获取关键科技激活的最高等级
function XUiRogueSimScience:GetLevelMaxActive()
    local techData = self._Control:GetTechData()
    local levelCfgs = self._Control:GetRogueSimTechLevelConfigs()

    local levelMaxActive = 0
    for lv, levelCfg in ipairs(levelCfgs) do
        if lv <= self.TechLv then 
            if levelCfg.Num == 0 then
                levelMaxActive = lv
            else
                local techLevelData = techData.LevelData[lv]
                levelMaxActive = lv

                -- 逐级激活，当前等级未激活所有关键科技
                if not techLevelData or #techLevelData.KeyTechs < levelCfg.Num then
                    return levelMaxActive
                end
            end
        end
    end

    return levelMaxActive
end

-- 获取 科技等级:主城等级 的哈希表
function XUiRogueSimScience:GetTechLvToMainLvDic()
    local techLvToMainLvDic = {}
    local levelIds = self._Control:GetMainLevelList()
    for _, id in ipairs(levelIds) do
        local mainLv = self._Control:GetMainLevelConfigLevel(id)
        local techLv = self._Control:GetMainLevelUnlockTechLevel(id)
        techLvToMainLvDic[techLv] = mainLv
    end
    return techLvToMainLvDic
end

function XUiRogueSimScience:InitTechLv()
    local lvStr = self._Control:GetClientConfig("Lv")
    for techLv, mainLv in pairs(self.TechLvToMainLvDic) do
        local txtLv = self["TxtLv"..tostring(techLv)]
        if txtLv then
            txtLv.text = string.format(lvStr, mainLv)
        end
    end
end

return XUiRogueSimScience
