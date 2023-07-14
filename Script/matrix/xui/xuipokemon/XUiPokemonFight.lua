local XUiPokemonFight = XLuaUiManager.Register(XLuaUi,"UiPokemonFight")

function XUiPokemonFight:OnStart()
    self.Btns = {}
    self:RegisterClickEvent(self.BtnMaskB,function()
        self:Close()
    end)
    self:InitButton()
end

function XUiPokemonFight:OnEnable()

end

function XUiPokemonFight:InitButton()
    local skipList = XDataCenter.PokemonManager.GetSkipStageInfo()
    for i = 1,#skipList do
        local id = skipList[i]
        local index = XPokemonConfigs.GetStageIdByFightStageId(XDataCenter.PokemonManager.GetCurrActivityId(),id)
        ---@type UnityEngine.GameObject
        local obj = CS.UnityEngine.GameObject.Instantiate(self.BtnEnterArena,self.PanelButton)
        obj.gameObject:SetActiveEx(true)
        ---@type XUiComponent.XUiButton
        local btn = obj:GetComponent("XUiButton")
        btn:SetName(XDataCenter.PokemonManager.GetStageName(index))
        btn.CallBack = function()
            self:Close()
            XLuaUiManager.Open("UiPokemonStageDetail",index)
        end
        table.insert(self.Btns,btn)
    end
end

return XUiPokemonFight