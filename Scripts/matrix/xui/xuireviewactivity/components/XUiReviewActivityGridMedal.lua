
local XUiReviewActivityGridMedal = XClass(nil, "XUiReviewActivityGridMedal")

function XUiReviewActivityGridMedal:Ctor(ui)
    XTool.InitUiObjectByUi(self, ui)
end

function XUiReviewActivityGridMedal:RefreshData(medalInfo)
    self.Data = medalInfo
    local data = XDataCenter.MedalManager.GetMedalById(medalInfo.Id)
    if data and data.MedalImg ~= nil then
        self.ImgMedalIcon:SetRawImage(data.MedalImg)
    end
    self.TxtMedalName.text = data.Name
    self.TxtMedalTime.text = XUiHelper.GetText("DayOfGetMedal", XTime.TimestampToGameDateTimeString(data.Time))
end

function XUiReviewActivityGridMedal:PlayEnableAnime(index) --该index是当前使用的grid中的序号，不是总grid里的动态列表组件上的属性的index,etc:共10个gird，若只显示最后5个且该格子是第10个的话，参数Index就是5
    self.GameObject:SetActive(false)
    XScheduleManager.ScheduleOnce(function()
        if not XTool.UObjIsNil(self.Transform) then
            self.GameObject:SetActive(true)
            self.Transform:Find("Animation/GridMedalEnable"):PlayTimelineAnimation(function ()
            end)
        end
    end, (index) * 95)
end

return XUiReviewActivityGridMedal