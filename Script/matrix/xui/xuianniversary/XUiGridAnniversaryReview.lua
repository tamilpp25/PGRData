--周年回顾列表元素逻辑代理
local XUiGridAnniversaryReview=XClass(XUiNode,'XUiGridAnniversaryReview')
local XUiGridAnniversaryReviewData=require('XUi/XUiAnniversary/XUiGridAnniversaryReviewData')

function XUiGridAnniversaryReview:OnStart()
    --初始化数据显示UI
    self.DataUICtrl={}
    for i=0,100 do
        if self['PanelUI'..i] then
            self.DataUICtrl['PanelUI'..i]=XUiGridAnniversaryReviewData.New(self['PanelUI'..i],self)
        end
    end
end

function XUiGridAnniversaryReview:Refresh(index)
    
    --获取配置：动态列表是从1开始的，配置表id是从0开始的，因此要-1
    local cfg=self._Control:GetReviewPictures()[index-1]
    --设置显示的图片
    self.ImgReview:SetRawImage(cfg.Address)

    --设置显示的UI
    for i, v in pairs(self.DataUICtrl) do
        v:Close()
    end
    for i, v in pairs(cfg.DisplayShowUI) do
        local uicfg=self._Control:GetAnniversaryReviewDataUIById(v)
        
        if uicfg and self[uicfg.UiName] then
            self.DataUICtrl[uicfg.UiName]:Open()
            self.DataUICtrl[uicfg.UiName]:Refresh(uicfg.DataType)
        end
    end
end


return XUiGridAnniversaryReview