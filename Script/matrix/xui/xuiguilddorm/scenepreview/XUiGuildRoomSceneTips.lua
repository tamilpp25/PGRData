local XUiGuildRoomSceneTips = XLuaUiManager.Register(XLuaUi,"UiGuildRoomSceneTips")

function XUiGuildRoomSceneTips:OnStart(themeId)
    self.ThemeId = themeId
    self:InitLabels()
    self.BtnTanchuangClose.CallBack = function()
        self:Close()
    end
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
    end
end

function XUiGuildRoomSceneTips:InitLabels()
    local config = XGuildDormConfig.GetThemeCfgById(self.ThemeId)
    local labelList = config.Labels
    local labelIdList = {}
    for _, labelStr in ipairs(labelList) do
       local labelIdStrList = string.Split(labelStr, "|")
        for _, id in ipairs(labelIdStrList) do
            table.insert(labelIdList, id)
        end
    end
    for _, labelId in ipairs(labelIdList) do
        local labelConfig = XGuildDormConfig.GetLabelConfigById(tonumber(labelId))
        local obj = CS.UnityEngine.GameObject.Instantiate(self.GridLabel, self.PanelLabel)
        local imgBg = obj.transform:Find("ImgBg"):GetComponent(typeof(CS.UnityEngine.UI.Image))
        local txtName = obj.transform:Find("ImgBg/TxtName"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        local txtContent = obj.transform:Find("ImgBg/Img02/TxtContent"):GetComponent(typeof(CS.UnityEngine.UI.Text))
        imgBg.color = XUiHelper.Hexcolor2Color(labelConfig.BgColor)
        txtName.text = labelConfig.Name
        txtContent.text = labelConfig.Content
    end
    
    self.GridLabel.gameObject:SetActiveEx(false)
end

return XUiGuildRoomSceneTips