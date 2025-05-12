---@class XUiMechanismTeamDetail
---@field _Control XMechanismActivityControl
local XUiMechanismTeamDetail = XLuaUiManager.Register(XLuaUi, 'UiMechanismTeamDetail')
local XUiGridMechanismTeamTab = require('XUi/XUiMechanismActivity/UiMechanismTeamDetail/XUiGridMechanismTeamTab')
local XUiGridMechanismBuff = require('XUi/XUiMechanismActivity/UiMechanismChapter/XUiGridMechanismBuff')

function XUiMechanismTeamDetail:OnAwake()
    self.BtnTanchuangCloseBig.CallBack = handler(self, self.Close)
end

function XUiMechanismTeamDetail:OnStart(index, mechanismCharaIndex)
    self._SelectIndex = index
    self._MechanismCharaIndex = mechanismCharaIndex
    self._ChapterId = self._Control:GetMechanismCurChapterId()
    if not XTool.IsNumberValid(self._ChapterId) then
        self.PanelTab.gameObject:SetActiveEx(false)
        self.PanelDetail.gameObject:SetActiveEx(false)
        self:Close()
        return
    end
    
    self:InitBtnGroup()
    self:InitPanelDetail()
    self:RefreshBtnGroup(true)
end

function XUiMechanismTeamDetail:OnEnable()
    self:RefreshBtnGroup()
end

--region 单选框组
function XUiMechanismTeamDetail:InitBtnGroup()
    self.PanelTab.gameObject:SetActiveEx(true)
    self._BtnGroup = {}
    local buttons = {}
    local characterCfgs = XMVCA.XMechanismActivity:GetMechanismCharacterCfgsByChapterId(self._ChapterId)
    XUiHelper.RefreshCustomizedList(self.BtnTab.transform.parent, self.BtnTab, characterCfgs and #characterCfgs or 0, function(index, obj)
        local grid = XUiGridMechanismTeamTab.New(obj, self, index)
        grid:Open()
        grid:Refresh(characterCfgs[index])
        table.insert(self._BtnGroup, grid)
        
        local xuibutton = obj.transform:GetComponent(typeof(CS.XUiComponent.XUiButton))
        if xuibutton then
            table.insert(buttons, xuibutton)
        end
    end)
    
    self.PanelTab:InitBtns(buttons,handler(self,self.OnBtnGroupClick))
end

function XUiMechanismTeamDetail:RefreshBtnGroup(force)
    self:SelectPanelTab(self._SelectIndex, force)
end

function XUiMechanismTeamDetail:SelectPanelTab(index, force)
    self._Force = force
    self.PanelTab:SelectIndex(index)
end

function XUiMechanismTeamDetail:OnBtnGroupClick(index)
    local force = self._Force
    self._Force = nil
    if self._SelectIndex == index and not force then
        return
    end

    self._SelectIndex = index
    
    for i, v in ipairs(self._BtnGroup) do
        v:SetSelection(false)
    end
    
    self._BtnGroup[index]:SetSelection(true)
    local mechanismCharaIndex = self._BtnGroup[index]:GetMechanismCharacterId()
    
    -- 刷新切页
    self:RefreshDetail(mechanismCharaIndex)
end
--endregion

--region 切页
function XUiMechanismTeamDetail:InitPanelDetail()
    self._PanelDetail = {}
    self._BuffGrids = {}
    XTool.InitUiObjectByUi(self._PanelDetail, self.PanelDetail)
    self._PanelDetail.GridBuff.gameObject:SetActiveEx(false)
end

function XUiMechanismTeamDetail:RefreshDetail(mechanismCharaIndex)
    local cfg = self._Control:GetMechanismCharacterCfgByIndex(mechanismCharaIndex)
    if cfg then
        self.PanelDetail.gameObject:SetActiveEx(true)
        -- 角色名
        self._PanelDetail.TxtName.text = XMVCA.XCharacter:GetCharacterFullNameStr(cfg.CharacterId)
        -- 拼接特效描述
        local titles = {}
        for i = 1, #cfg.CharacterTitles do
            local content = XUiHelper.FormatText(self._Control:GetMechanismClientConfigStr('CommonTitleFormat'), cfg.CharacterTitles[i], cfg.CharacterDesc[i])
            table.insert(titles, content)
            table.insert(titles, '\n')
        end
        titles[#titles] = nil
        self._PanelDetail.TxtTips.text = table.concat(titles)
        -- 显示buff
        for i, v in ipairs(self._BuffGrids) do
            self._BuffGrids[i]:Close()
        end

        for i, v in ipairs(cfg.BuffIcons) do
            if self._BuffGrids[i] then
                self._BuffGrids[i]:Open()
                self._BuffGrids[i]:Refresh(cfg.Id, i, true)
            else
                local clone = CS.UnityEngine.GameObject.Instantiate(self._PanelDetail.GridBuff, self._PanelDetail.GridBuff.transform.parent)
                local grid = XUiGridMechanismBuff.New(clone, self)
                grid:Open()
                grid:Refresh(cfg.Id, i, true)
                self._BuffGrids[i] = grid
            end
        end
    else
        self.PanelDetail.gameObject:SetActiveEx(false)
    end
end
--endregion
return XUiMechanismTeamDetail