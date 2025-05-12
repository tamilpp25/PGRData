---@class XUiPanelPcgGameDetail : XUiNode
---@field private _Control XPcgControl
---@field Parent XUiPcgGame
local XUiPanelPcgGameDetail = XClass(XUiNode, "XUiPanelPcgGameDetail")

function XUiPanelPcgGameDetail:OnStart()
    self:RegisterUiEvents()

    -- UI上根据4 2 1 3 5的顺序显示。中间+右边为true显示Left，左边false显示Right
    self.IndexToPanelSideDic = {true, false, true, false, true}
end

function XUiPanelPcgGameDetail:OnEnable()
    
end

function XUiPanelPcgGameDetail:OnDisable()
    
end

function XUiPanelPcgGameDetail:OnDestroy()
    self.DetailGo = nil
end

function XUiPanelPcgGameDetail:RegisterUiEvents()
    XUiHelper.RegisterClickEvent(self, self.BtnCloseBg, self.OnBtnCloseClick, nil, true)
end

function XUiPanelPcgGameDetail:OnBtnCloseClick()
    self:SetDetailShow(false)
end

function XUiPanelPcgGameDetail:GetIsDetailShow()
    return self.IsDetailShow == true
end

function XUiPanelPcgGameDetail:SetDetailShow(isShow)
    self.BtnCloseBg.gameObject:SetActiveEx(isShow)
    self.PopupDetailLink.gameObject:SetActiveEx(isShow)
    self.IsDetailShow = isShow
end

function XUiPanelPcgGameDetail:Refresh(type, idx)
    self:SetDetailShow(true)
    -- 加载预制体
    local path = self._Control:GetClientConfig("PopupDetailPrefabs", type)
    self.DetailGo = self.PopupDetailLink:LoadPrefab(path)
    -- 切换预置时标记预制体销毁
    if self.LastPath ~= path then
        self.GridTokens = {}
        self.LastPath = path
    end
    -- 刷新UI
    local position = nil
    if type == XEnumConst.PCG.POPUP_DETAIL_TYPE.COMMANDER then
        position = self.Parent.UiPanelCommander:GetCommanderPosition()
        self:RefreshCommanderDetail()
    elseif type == XEnumConst.PCG.POPUP_DETAIL_TYPE.MONSTER then
        position = self.Parent.UiPanelMonster:GetMonsterPosition(idx)
        self:RefreshMonsterDetail(idx)
    elseif type == XEnumConst.PCG.POPUP_DETAIL_TYPE.CHARACTER then
        position = self.Parent.UiPanelCharacter:GetCharacterPosition(idx)
        self:RefreshCharacterDetail(idx)
    end
    self.PopupDetailLink.position = position
end

-- 怪物详情
function XUiPanelPcgGameDetail:RefreshMonsterDetail(idx)
    local detailUiObj = self.DetailGo:GetComponent("UiObject")
    local leftUiObj = detailUiObj:GetObject("Left")
    local rightUiObj = detailUiObj:GetObject("Right")
    local isLeft = self.IndexToPanelSideDic[idx] == true
    leftUiObj.gameObject:SetActiveEx(isLeft)
    rightUiObj.gameObject:SetActiveEx(not isLeft)

    local uiObj = isLeft and leftUiObj or rightUiObj
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgMonster
    local monsterData = stageData:GetMonster(idx)
    local id = monsterData:GetId()
    local hp = monsterData:GetHp()
    ---@type XBehaviorPreview[]
    local behaviorPreviews = monsterData:GetBehaviorPreviews()
    local monsterCfg = self._Control:GetConfigMonster(id)
    
    -- 名称、血量
    uiObj:GetObject("TxtName").text = monsterCfg.Name
    uiObj:GetObject("TxtHpNum").text = tostring(hp) .. "/" .. tostring(monsterCfg.MaxHp)
    -- 行动预览
    local isShowPreview = #behaviorPreviews > 0
    uiObj:GetObject("PanelIntent").gameObject:SetActiveEx(isShowPreview)
    if isShowPreview then
        local icon, txt = self._Control.GameSubControl:GetMonsterBehaviorPreviewsIconAndTxt(behaviorPreviews)
        if icon then
            uiObj:GetObject("RImgIntent"):SetRawImage(icon)
        end
        uiObj:GetObject("TxtIntentNum").text = txt
        local txtDetail = uiObj:GetObject("TxtDetail")
        txtDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
        txtDetail.text = XUiHelper.ReplaceTextNewLine(self:GetMonsterBehaviorDesc(behaviorPreviews))
    end
    -- 刷新Tokens
    local item = uiObj:GetObject("UiPcgGridEffectDetail")
    local tokens = monsterData:GetTokens()
    self:RefreshTokens(item, tokens)
end

-- 刷新角色详情
function XUiPanelPcgGameDetail:RefreshCharacterDetail(idx)
    local detailUiObj = self.DetailGo:GetComponent("UiObject")
    local leftUiObj = detailUiObj:GetObject("Left")
    local rightUiObj = detailUiObj:GetObject("Right")
    local isLeft = self.IndexToPanelSideDic[idx] == true
    leftUiObj.gameObject:SetActiveEx(isLeft)
    rightUiObj.gameObject:SetActiveEx(not isLeft)

    local uiObj = isLeft and leftUiObj or rightUiObj
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCharacter
    local characterData = stageData:GetCharacter(idx)
    local cfg = self._Control:GetConfigCharacter(characterData:GetId())
    local typeCfg = self._Control:GetConfigCharacterType(cfg.Type)
    
    -- 刷新角色详情
    uiObj:GetObject("TxtName").text = cfg.Name
    local txtCharacterDetail = uiObj:GetObject("TxtCharacterDetail")
    txtCharacterDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
    txtCharacterDetail.text = XUiHelper.ReplaceTextNewLine(cfg.Desc)
    uiObj:GetObject("TxtType").text = typeCfg.Name
    uiObj:GetObject("RImgTypeIcon"):SetRawImage(typeCfg.Icon)
    local txtQteDetail = uiObj:GetObject("TxtQteDetail")
    txtQteDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
    txtQteDetail.text = cfg.QteDesc

    -- 刷新Tokens
    local item = uiObj:GetObject("UiPcgGridEffectDetail")
    local tokens = characterData:GetTokens()
    self:RefreshTokens(item, tokens)
end

-- 指挥官详情
function XUiPanelPcgGameDetail:RefreshCommanderDetail()
    local uiObj = self.DetailGo:GetComponent("UiObject")
    ---@type XPcgPlayingStage
    local stageData = self._Control.GameSubControl:GetPlayingStageData()
    ---@type XPcgCommander
    local commander = stageData:GetCommander()
    local hp = commander:GetHp()
    local stageCfg = self._Control:GetConfigStage(stageData:GetId())
    
    -- 血量
    uiObj:GetObject("TxtHpNum").text = tostring(hp) .. "/" .. tostring(stageCfg.MaxHp)
    -- 主动技能
    local isShowSkill = stageCfg.EnablePlayerSkill == 1
    uiObj:GetObject("PanelSkill").gameObject:SetActiveEx(isShowSkill)
    if isShowSkill then
        local icon = self._Control:GetClientConfig("CommanderSkillIcon")
        local name = self._Control:GetClientConfig("CommanderSkillName")
        local desc = self._Control:GetClientConfig("CommanderSkillDesc")
        uiObj:GetObject("ImgSkillIcon"):SetSprite(icon)
        uiObj:GetObject("TxtSkillName").text = name

        local txtSkillDetail = uiObj:GetObject("TxtSkillDetail")
        txtSkillDetail.requestImage = XMVCA.XPcg.RichTextImageCallBack
        txtSkillDetail.text = desc
    end
    -- 刷新Tokens
    local item = uiObj:GetObject("UiPcgGridEffectDetail")
    local tokens = commander:GetTokens()
    self:RefreshTokens(item, tokens)
end

-- 刷新标记
---@param tokenDatas XPcgToken[]
function XUiPanelPcgGameDetail:RefreshTokens(item, tokenDatas)
    item.gameObject:SetActiveEx(false)
    for _, grid in ipairs(self.GridTokens) do
        grid:Close()
    end

    local CSInstantiate = CS.UnityEngine.Object.Instantiate
    local XUiGridPcgToken = require("XUi/XUiPcg/XUiGrid/XUiGridPcgToken")
    for i, tokenData in ipairs(tokenDatas) do
        local tokenId = tokenData:GetId()
        ---@type XUiGridPcgToken
        local grid = self.GridTokens[i]
        if not grid then
            local go = CSInstantiate(item, item.transform.parent)
            grid = XUiGridPcgToken.New(go, self)
            table.insert(self.GridTokens, grid)
        end
        grid.Transform:SetParent(item.transform.parent) -- 有Left和Right面板，支持XUiGridPcgToken复用
        grid:SetData(tokenId)
        
        local isShow = self._Control:GetTokenIsShow(tokenId)
        if isShow then
            grid:Open()
        else
            grid:Close()
        end
    end
end

-- 获取怪物行为描述
---@param behaviorPreviews XPcgBehaviorPreview[]
function XUiPanelPcgGameDetail:GetMonsterBehaviorDesc(behaviorPreviews)
    local behaviorId = behaviorPreviews[1]:GetBehaviorId()
    local behaviorCfg = self._Control:GetConfigMonsterBehavior(behaviorId)
    return behaviorCfg and behaviorCfg.Desc or ""
end

return XUiPanelPcgGameDetail
