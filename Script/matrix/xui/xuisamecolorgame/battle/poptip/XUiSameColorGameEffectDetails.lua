---@class XUiSameColorGameEffectDetails:XLuaUi
local XUiSameColorGameEffectDetails = XLuaUiManager.Register(XLuaUi, "UiSameColorGameEffectDetails")
function XUiSameColorGameEffectDetails:OnStart()
    self.GridBuffList = {}
    self.BattleManager = XDataCenter.SameColorActivityManager.GetBattleManager()
    self:SetButtonCallBack()
    self.GridBuff.gameObject:SetActiveEx(false)
end

function XUiSameColorGameEffectDetails:OnEnable()
    self:Refresh()
end

function XUiSameColorGameEffectDetails:Refresh()
    local buffList = self.BattleManager:GetShowBuffList()

    for i, buff in ipairs(buffList) do
        local grid = self.GridBuffList[i]
        if not grid then
            local go  = XUiHelper.Instantiate(self.GridBuff, self.GridBuff.transform.parent)
            go.gameObject:SetActiveEx(true)
            grid = go:GetComponent("UiObject")
            self.GridBuffList[i] = grid
        end
        self:RefreshGrid(grid, buff)
    end
end

---@param grid UiObject
---@param buff XSCBuff
function XUiSameColorGameEffectDetails:RefreshGrid(grid, buff)
    grid:GetObject("TxtName").text = buff:GetName()
    grid:GetObject("TxtDesc").text = buff:GetDesc()
    grid:GetObject("TxtCount").text = buff:GetCountDown()
    grid:GetObject("IconImage"):SetRawImage(buff:GetIcon())
    if buff:GetDuration() == 0 then
        grid:GetObject("TxtCount").text = ""
        grid:GetObject("ImgBg").gameObject:SetActiveEx(false)
    else
        grid:GetObject("TxtCount").text = buff:GetCountDown()
        grid:GetObject("ImgBg").gameObject:SetActiveEx(true)
    end
end

function XUiSameColorGameEffectDetails:SetButtonCallBack()
    self.BtnClose.CallBack = function() self:OnClickBtnBack() end
    self:RegisterClickEvent(self.BtnBg, self.Close)
end

function XUiSameColorGameEffectDetails:OnClickBtnBack()
    self:Close()
end