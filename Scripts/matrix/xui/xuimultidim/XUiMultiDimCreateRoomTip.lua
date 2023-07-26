local XUiMultiDimCreateRoomTip = XLuaUiManager.Register(XLuaUi,"UiMultiDimCreateRoomTip")
local XUiPanelMultiDimRoomSelectCareer = require("XUi/XUiMultiDim/XUiPanelMultiDimRoomSelectCareer")
function XUiMultiDimCreateRoomTip:OnStart(stageId)
    self.StageId = stageId
    self.DefaultRecommendList = XMultiDimConfig.GetMultiDimRecommendCareerList(stageId)
    self:InitView()
    self.BtnTanchuangCloseBig.CallBack = function()
        self:Close()
    end
    self.BtnTcanchaungCancel.CallBack = function()
        self:Close()
    end
    self.BtnTcanchaungCreate.CallBack = function()
        self:OnClickCreateRoom()
    end
end

function XUiMultiDimCreateRoomTip:InitView()
    local difficultyCfg = XMultiDimConfig.GetMultiDimDifficultyStageData(self.StageId)
    local presetCareerId = XDataCenter.MultiDimManager.GetPresetCareerId(difficultyCfg.Id)
    self.TxtType.text = XMultiDimConfig.GetMultiDimCareerName(presetCareerId)
    self.RImgIconType:SetRawImage(XMultiDimConfig.GetMultiDimCareerIcon(presetCareerId))
    self.TxtDetail.text = XUiHelper.ConvertLineBreakSymbol(XMultiDimConfig.GetMultiDimCareerDes(presetCareerId))
    local careers = XDataCenter.MultiDimManager.GetPrefabTeammateCareers(difficultyCfg.Id)
    if careers then
        self.PanelTeam2 = XUiPanelMultiDimRoomSelectCareer.New(self.PanelFriendType2,2,careers[1],self.StageId)
        self.PanelTeam3 = XUiPanelMultiDimRoomSelectCareer.New(self.PanelFriendType3,3,careers[2],self.StageId)
    else
        self.PanelTeam2 = XUiPanelMultiDimRoomSelectCareer.New(self.PanelFriendType2,2,self.DefaultRecommendList[2],self.StageId)
        self.PanelTeam3 = XUiPanelMultiDimRoomSelectCareer.New(self.PanelFriendType3,3,self.DefaultRecommendList[3],self.StageId)
    end
end

function XUiMultiDimCreateRoomTip:OnClickCreateRoom()
    self:Close()
    XDataCenter.RoomManager.CreateRoom(self.StageId)
end

return XUiMultiDimCreateRoomTip