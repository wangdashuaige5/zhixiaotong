// 请假时间表单：只修改弹窗草稿，点击确定才回填；取消不改变已选时间。
@CustomDialog
export struct LeaveTimeDialog {
  controller?: CustomDialogController;
  title: string = '';
  initialValue: Date = new Date();
  onConfirm: (value: Date) => void = () => {};
  @State draft: Date = new Date();

  aboutToAppear(): void { this.draft = new Date(this.initialValue.getTime()); }

  build() {
    Column({ space: 8 }) {
      Text(this.title).fontSize(20).fontWeight(FontWeight.Bold)
      DatePicker({ start: new Date(new Date().getFullYear() - 1, 0, 1),
        end: new Date(new Date().getFullYear() + 5, 11, 31), selected: this.draft })
        .height(180)
        .onChange((value: DatePickerResult) => {
          this.draft = new Date(value.year ?? this.draft.getFullYear(), value.month ?? this.draft.getMonth(),
            value.day ?? this.draft.getDate(), this.draft.getHours(), this.draft.getMinutes());
        })
      TimePicker({ selected: this.draft }).useMilitaryTime(true).height(140)
        .onChange((value: TimePickerResult) => {
          this.draft = new Date(this.draft.getFullYear(), this.draft.getMonth(), this.draft.getDate(),
            value.hour ?? this.draft.getHours(), value.minute ?? this.draft.getMinutes());
        })
      Row({ space: 12 }) {
        Button('取消').layoutWeight(1).onClick(() => this.controller?.close())
        Button('确定').layoutWeight(1).onClick(() => {
          this.onConfirm(new Date(this.draft.getTime()));
          this.controller?.close();
        })
      }.width('100%')
    }.padding(20).width('100%')
  }
}
