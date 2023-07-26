-- 肉鸽玩法二期外循环强化解锁提示
-- ================================================================================
local XUiBiancaTheatreUnlockTips = XLuaUiManager.Register(XLuaUi, "UiBiancaTheatreUnlockTips")

function XUiBiancaTheatreUnlockTips:OnAwake()
    self:AddClickListener()
end

function XUiBiancaTheatreUnlockTips:OnStart(callback)
    self.CallBack = callback
end

function XUiBiancaTheatreUnlockTips:AddClickListener()
    self:RegisterClickEvent(self.BtnClose, function ()
        XDataCenter.BiancaTheatreManager.SetStrengthenUnlockTipsCache()
        self:Close()
        if self.CallBack then
            self.CallBack()
        end
    end)
end