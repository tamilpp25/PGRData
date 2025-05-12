local XUiGridWorldBossTeamList = require("XUi/XUiWorldBoss/XUiGridWorldBossTeamList")
local XUiGridWorldBossAreaRankItem = XClass(nil, "XUiGridWorldBossAreaRankItem")

function XUiGridWorldBossAreaRankItem:Ctor(ui)
    self.GameObject = ui.gameObject
    self.Transform = ui.transform
    XTool.InitUiObject(self)
    self.BtnDetail.CallBack = function() self:OnBtnDetailClick() end
end

function XUiGridWorldBossAreaRankItem:Init(data)
    if data then
        self.Id = data.Id
        self.TxtScore.text = data.Score
        self.TxtName.text = data.Name
        self.TxtRank.text = data.Rank
        if self.Team == nil then
            self.Team = XUiGridWorldBossTeamList.New(self.TeamObj)
        end
        XUiPlayerHead.InitPortrait(data.HeadPortraitId, data.HeadFrameId, self.UObjHead)
        self.Team:Init(data.CharacterInfos) 
    end
end

function XUiGridWorldBossAreaRankItem:OnBtnDetailClick()
    if self.Id ~= XPlayer.Id then
        XDataCenter.PersonalInfoManager.ReqShowInfoPanel(self.Id)
    end
end

return XUiGridWorldBossAreaRankItem