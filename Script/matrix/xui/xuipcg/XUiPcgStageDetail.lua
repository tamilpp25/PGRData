---@class XUiPcgStageDetail : XLuaUi
---@field private _Control XPcgControl
local XUiPcgStageDetail = XLuaUiManager.Register(XLuaUi, "UiPcgStageDetail")

function XUiPcgStageDetail:OnAwake()
    self.PaneChoseCharacter.gameObject:SetActiveEx(false)
    self.PanelMonsterDetail.gameObject:SetActiveEx(false)
    self:RegisterUiEvents()
    self:InitCharacters()
end

function XUiPcgStageDetail:OnStart(stageId, characters)
    self.StageId = stageId
    self.CharacterIds = characters or {0, 0, 0}   -- 当前队伍角色Id列表
    
    -- 教学关根据配表显示角色
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    self.StageType = stageCfg.Type
    if self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING then
        self.CharacterIds = self._Control:GetStageRecommendCharacterIds(self.StageId)
    end
end

function XUiPcgStageDetail:OnEnable()
    self:Refresh()
end

function XUiPcgStageDetail:OnDisable()
    
end

function XUiPcgStageDetail:OnGetLuaEvents()
    return {
        XEventId.EVENT_PCG_SHOW_DETAIL,
    }
end

function XUiPcgStageDetail:OnNotify(evt, ...)
    local args = {...}
    if evt == XEventId.EVENT_PCG_SHOW_DETAIL then
        local isShow = args[3] == "1"
        self:ShowMonsterDetail(isShow)
    end
end

function XUiPcgStageDetail:RegisterUiEvents()
    self:RegisterClickEvent(self.BtnBack, self.OnBtnBackClick)
    self:RegisterClickEvent(self.BtnMainUi, self.OnBtnMainUiClick)
    self:RegisterClickEvent(self.BtnStart, self.OnBtnStartClick)
    self:RegisterClickEvent(self.BtnRecommend, self.OnBtnRecommendClick)
    self:BindHelpBtn(self.BtnHelp, self._Control:GetClientConfig("HelpKey"))
    self.PressAreaInputHandler:AddPointerUpListener(function(eventData)
        self:OnPointerUp(eventData)
    end)
    self.PressAreaInputHandler:AddPressListener(function(time)
        self:OnPress(time)
    end)
end

function XUiPcgStageDetail:OnBtnBackClick()
    if self.UiPaneChoseCharacter and self.UiPaneChoseCharacter:IsNodeShow() then
        self.UiPaneChoseCharacter:OnBtnCloseClick()
        return
    end
    self:Close()
end

function XUiPcgStageDetail:OnBtnMainUiClick()
    XLuaUiManager.RunMain()
end

function XUiPcgStageDetail:OnBtnStartClick()
    -- 已有正在进行中的关卡
    local curStageId = self._Control:GetCurrentStageId()
    if XTool.IsNumberValid(curStageId) and curStageId ~= self.StageId then
        local tips = self._Control:GetClientConfig("ChallengeFailTips")
        XUiManager.TipError(tips)
        return
    end
                         
    -- 未选择足够角色提示
    local charCnt = self:GetSelCharacterCnt()
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    if charCnt < stageCfg.NeedCharNum then
        local tipsFormat = self._Control:GetClientConfig("NoSelectedEnoughCharacterTips")
        local tips = string.format(tipsFormat, stageCfg.NeedCharNum)
        XUiManager.TipError(tips)
        return
    end
    
    XMVCA.XPcg:PcgStageBeginRequest(self.StageId, self.CharacterIds, function()
        XLuaUiManager.Open("UiPcgGame")
        XLuaUiManager.Remove("UiPcgStageDetail")
    end)
end

-- 点击推荐按钮
function XUiPcgStageDetail:OnBtnRecommendClick()
    if self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING then
        local tips = self._Control:GetClientConfig("NoChangeCharacterTips")
        XUiManager.TipError(tips)
        return
    end
    
    self.CharacterIds = self._Control:GetStageRecommendCharacterIds(self.StageId)
    self:RefreshCharacters()
end

-- 点击角色
function XUiPcgStageDetail:OnCharacterClick(index)
    -- 上锁
    local isLock = self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING and self.CharacterIds[index] == 0
    if isLock then
        local tips = self._Control:GetClientConfig("NoSelectCharacterTips")
        XUiManager.TipError(tips)
        return
    end
    
    -- 无解锁角色可选
    local characterIds = self._Control:GetUnlockCharacterIds(self.StageId, index)
    if #characterIds == 0 then
        local tips = self._Control:GetClientConfig("NoSelectCharacterTips")
        XUiManager.TipError(tips)
        return
    end
    
    self:OpenPaneChoseCharacter(index)
end

function XUiPcgStageDetail:OnPointerUp(eventData)
    self:ShowMonsterDetail(false)
end

function XUiPcgStageDetail:OnPress(time)
    -- 长按超过0.2秒才响应操作
    if time < 0.2 then return end

    if not self.IsShowDetail then
        self:ShowMonsterDetail(true)
    end
end

-- 切换角色
function XUiPcgStageDetail:OnChangeCharacter(index, characterId)
    self.CharacterIds[index] = characterId
    self:Refresh()
end

function XUiPcgStageDetail:GetStageId()
    return self.StageId
end

-- 刷新界面
function XUiPcgStageDetail:Refresh()
    self:RefreshStageInfo()
    self:RefreshCharacters()
end

-- 刷新关卡信息
function XUiPcgStageDetail:RefreshStageInfo()
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    self.TxtTitle.text = stageCfg.Name

    local isTeaching = self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING 
    self.BtnRecommend.gameObject:SetActiveEx(not isTeaching)
    self.PanelNormalStage.gameObject:SetActiveEx(false)
    self.PanelEndlessStage.gameObject:SetActiveEx(false)
    if stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.TEACHING 
    or stageCfg.Type == XEnumConst.PCG.STAGE_TYPE.NORMAL then
        -- 教学关/普通关
        self:RefreshPanelNormalStage()
    else
        -- 无尽关
        self:RefreshPanelEndlessStage()
    end
    self:RefreshMonsterInfo()
end

-- 刷新教学关/普通关
function XUiPcgStageDetail:RefreshPanelNormalStage()
    -- 胜利条件
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    self.PanelNormalStage.gameObject:SetActiveEx(true)
    local uiObj = self.PanelNormalStage:GetComponent("UiObject")
    uiObj:GetObject("TxtWinDetail").text = stageCfg.FinishDesc
    -- 三星条件
    local stageRecord = self._Control:GetActivityData():GetStageRecord(self.StageId)
    local stars = stageRecord and stageRecord:GetStars() or 0
    local gridStar = uiObj:GetObject("GridStageStar")
    gridStar.gameObject:SetActiveEx(false)
    self.StarUiObjs = self.StarUiObjs or {}
    for _, starUiObj in ipairs(self.StarUiObjs) do
        starUiObj.gameObject:SetActiveEx(false)
    end
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, desc in ipairs(stageCfg.StarDesc) do
        local starUiObj = self.StarUiObjs[i]
        if not starUiObj then
            local go = CSInstantiate(gridStar.gameObject, gridStar.transform.parent)
            starUiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.StarUiObjs, starUiObj)
        end
        starUiObj.gameObject:SetActiveEx(true)
        local isActive = i <= stars
        starUiObj:GetObject("PanelActive").gameObject:SetActiveEx(isActive)
        starUiObj:GetObject("PanelUnActive").gameObject:SetActiveEx(not isActive)
        starUiObj:GetObject("TxtActive").text = desc
        starUiObj:GetObject("TxtUnActive").text = desc
    end
end

-- 刷新无尽关
function XUiPcgStageDetail:RefreshPanelEndlessStage()
    self.PanelEndlessStage.gameObject:SetActiveEx(true)
    local panelUiObj = self.PanelEndlessStage:GetComponent("UiObject")

    -- 关卡词缀
    local effectGo = panelUiObj:GetObject("UiPcgGridEffectDetail")
    effectGo.gameObject:SetActiveEx(false)
    self.EffectObjs = self.EffectObjs or {}
    for _, uiObj in ipairs(self.EffectObjs) do
        uiObj.gameObject:SetActiveEx(false)
    end
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, icon in ipairs(stageCfg.StageTokenIcons) do
        local uiObj = self.EffectObjs[i]
        if not uiObj then
            local go = CSInstantiate(effectGo.gameObject, effectGo.transform.parent)
            uiObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.EffectObjs, uiObj)
        end
        uiObj.gameObject:SetActiveEx(true)
        uiObj:GetObject("RImgIcon"):SetRawImage(icon)
        uiObj:GetObject("TxtTitle").text = stageCfg.StageTokenNames[i]
        uiObj:GetObject("TxtDetail").text = stageCfg.StageTokenDescs[i]
    end

    -- 轮次、分数记录
    ---@type XPcgStageRecord
    local stageRecord = self._Control:GetActivityData():GetStageRecord(self.StageId)
    local score = stageRecord and stageRecord:GetScore() or "-"
    local monsterLoop = stageRecord and stageRecord:GetMonsterLoop() or "-"
    panelUiObj:GetObject("TxtScoreNum").text = tostring(score)
    panelUiObj:GetObject("TxtRoundNum").text = tostring(monsterLoop)
end

-- 刷新怪物信息
function XUiPcgStageDetail:RefreshMonsterInfo()
    -- 怪物信息
    local monsterId = self._Control:GetStageBossMonsterId(self.StageId)
    local monsterCfg = self._Control:GetConfigMonster(monsterId)
    self.RImgMonsterHalfBody:SetRawImage(monsterCfg.HalfBodyIcon)
    self.TxtHpNum.text = tostring(monsterCfg.MaxHp)

    -- 怪物标记
    local tokenDatas = {}
    for i, tokenId in ipairs(monsterCfg.InitialTokens) do
        local layer = monsterCfg.InitialTokensLayer[i]
        if tokenId ~= 0 then
            table.insert(tokenDatas, { Id = tokenId, Layer = layer })
        end
    end
    self:RefreshTokens(self.GridToken, tokenDatas)
end

-- 刷新怪物标记
function XUiPcgStageDetail:RefreshTokens(gridToken, tokenDatas)
    self.TokenObjs = self.TokenObjs or {}
    gridToken.gameObject:SetActiveEx(false)
    for _, tokenObj in ipairs(self.TokenObjs) do
        tokenObj.gameObject:SetActiveEx(false)
    end
    if not tokenDatas or #tokenDatas == 0 then return end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    for i, tokenData in ipairs(tokenDatas) do
        local tokenObj = self.TokenObjs[i]
        if not tokenObj then
            local go = CSInstantiate(gridToken.gameObject, gridToken.transform.parent)
            tokenObj = go:GetComponent(typeof(CS.UiObject))
            table.insert(self.TokenObjs, tokenObj)
        end
        local tokenCfg = self._Control:GetConfigToken(tokenData.Id)
        tokenObj.gameObject:SetActiveEx(tokenCfg.IsShow == 1)
        tokenObj:GetObject("RImgToken"):SetRawImage(tokenCfg.Icon)
        tokenObj:GetObject("TxtTokenNum").text = "x" .. tokenData.Layer
    end
end

function XUiPcgStageDetail:InitCharacters()
    local XUiGridPcgCharacter = require("XUi/XUiPcg/XUiGrid/XUiGridPcgCharacter")
    ---@type table<number, XUiGridPcgCharacter>
    self.GridCharacterDic = {}
    for i = 1, XEnumConst.PCG.MAX_CHAR_CNT do
        local go = self["GridCharacter" .. i]
        ---@type XUiGridPcgCharacter
        local grid = XUiGridPcgCharacter.New(go, self)
        self.GridCharacterDic[i] = grid
        grid:Open()
        grid:SetColorType(i)
        grid:SetInputCallBack(function(idx)
            self:OnCharacterClick(idx)
        end)
    end
end

-- 刷新角色列表
function XUiPcgStageDetail:RefreshCharacters()
    local isTeaching = self.StageType == XEnumConst.PCG.STAGE_TYPE.TEACHING
    for i, charId in ipairs(self.CharacterIds) do
        ---@type XUiGridPcgCharacter
        local grid = self.GridCharacterDic[i]
        grid:SetCharacterData(charId, i)
        if isTeaching then
            local isLock = charId == 0
            local isAdd = not isLock and charId == 0
            grid:SetLock(isLock)
            grid:SetAdd(isAdd)
        end
    end

    -- 刷新挑战按钮
    local charCnt = self:GetSelCharacterCnt()
    local stageCfg = self._Control:GetConfigStage(self.StageId)
    local isEnough = charCnt >= stageCfg.NeedCharNum
    self.BtnStart:SetDisable(not isEnough)

    -- 刷新队伍名称
    local teamName = self._Control:GetTeamName(self.CharacterIds)
    local isShow = not string.IsNilOrEmpty(teamName)
    self.PanelTeamTitle.gameObject:SetActiveEx(isShow)
    if isShow then
        self.TxtTeamTitle.text = teamName
    end
end

-- 打开选择角色面板
function XUiPcgStageDetail:OpenPaneChoseCharacter(index)
    if not self.UiPaneChoseCharacter then
        ---@type XUiPanelChoseCharacter
        self.UiPaneChoseCharacter = require("XUi/XUiPcg/XUiPcgStageDetail/XUiPanelChoseCharacter").New(self.PaneChoseCharacter, self)
    end
    self.UiPaneChoseCharacter:Open()
    self.UiPaneChoseCharacter:Refresh(self.StageId, index, self.CharacterIds[index])
    self:SetCharacterLayer(index)
end

function XUiPcgStageDetail:ShowMonsterDetail(isShow)
    if self.IsShowDetail == isShow then return end
    
    self.IsShowDetail = isShow
    self.PanelMonsterDetail.gameObject:SetActiveEx(isShow)
    if isShow then
        self:RefreshMonsterDetail()
    end
end

-- 刷新怪物详情
function XUiPcgStageDetail:RefreshMonsterDetail()
    local uiObj = self.PanelMonsterDetail
    local monsterId = self._Control:GetStageBossMonsterId(self.StageId)
    local monsterCfg = self._Control:GetConfigMonster(monsterId)
    
    -- 名称、血量
    uiObj:GetObject("TxtName").text = monsterCfg.Name
    uiObj:GetObject("TxtHpNum").text = tostring(monsterCfg.MaxHp) .. "/" .. tostring(monsterCfg.MaxHp)
    -- 刷新Tokens
    local item = uiObj:GetObject("UiPcgGridEffectDetail")
    item.gameObject:SetActiveEx(false)
    self.GridTokens = self.GridTokens or {}
    for _, grid in ipairs(self.GridTokens) do
        grid:Close()
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridPcgToken = require("XUi/XUiPcg/XUiGrid/XUiGridPcgToken")
    for i, tokenId in ipairs(monsterCfg.InitialTokens) do
        ---@type XUiGridPcgToken
        local grid = self.GridTokens[i]
        if not grid then
            local go = CSInstantiate(item, item.transform.parent)
            grid = XUiGridPcgToken.New(go, self)
            table.insert(self.GridTokens, grid)
        end
        grid:SetData(tokenId)
        local isShow = self._Control:GetTokenIsShow(tokenId)
        if isShow then
            grid:Open()
        else
            grid:Close()
        end
    end
end

-- 获取选择角色数量
function XUiPcgStageDetail:GetSelCharacterCnt()
    local charCnt = 0
    for _, charId in ipairs(self.CharacterIds) do
        if charId ~= 0 then
            charCnt = charCnt + 1
        end
    end
    return charCnt
end

-- 设置角色层级
function XUiPcgStageDetail:SetCharacterLayer(topIndex)
    for i = 1, XEnumConst.PCG.MAX_CHAR_CNT do
        local isTop = topIndex == i
        self["GridCharacter" .. i]:GetComponent("Canvas").overrideSorting = isTop
    end
end

return XUiPcgStageDetail
