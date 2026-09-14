import { promptAction } from '@kit.ArkUI';
import { ApiException } from '../common/Http';
import { AppTheme } from '../common/Theme';
import { CampusApi } from '../services/Api';
import { SemesterItem, TimetableItem } from '../model/Models';

class SelectOptionItem {
  value: string;

  constructor(value: string) {
    this.value = value;
  }
}

@Entry
@Component
struct TimetablePage {
  @State semesters: SemesterItem[] = [];
  @State semesterOptions: SelectOptionItem[] = [];
  @State weekOptions: SelectOptionItem[] = [];
  @State selectedSemesterIndex: number = 0;
  @State currentSemesterId: string = '';
  @State semesterStart: string = '';
  @State selectedWeek: number = 1;
  @State todayText: string = '';
  @State items: TimetableItem[] = [];
  @State maxPeriod: number = 6;
  @State loading: boolean = true;
  @State error: string = '';

  private courseColors: string[] = ['#E5EAF6', '#E8F3E8', '#FFF1E5', '#FDEBEC', '#F3E8FD', '#E8F6F8'];

  async loadSemesters(): Promise<void> {
    this.loading = true;
    this.error = '';
    try {
      this.semesters = await CampusApi.semesters();
      this.semesterOptions = this.semesters.map((item: SemesterItem) => new SelectOptionItem(item.semester_name));
      let currentIndex = this.semesters.findIndex((item: SemesterItem) => item.is_current === 1);
      if (currentIndex < 0) {
        currentIndex = 0;
      }
      this.selectedSemesterIndex = currentIndex;
      let current = this.semesters[currentIndex];
      this.currentSemesterId = current.id;
      this.semesterStart = current.start_date;
      this.todayText = this.dateText(new Date());
      this.weekOptions = [];
      for (let i = 1; i <= current.week_count; i++) {
        this.weekOptions.push(new SelectOptionItem(`第${i}周`));
      }
      let week = this.currentWeek(current.start_date);
      if (week < 1) {
        week = 1;
      }
      if (week > current.week_count) {
        week = current.week_count;
      }
      this.selectedWeek = week;
      await this.loadTimetable();
    } catch (e) {
      let message = '学期加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  currentWeek(startDate: string): number {
    let start = new Date(`${startDate}T00:00:00+08:00`);
    let offset = (start.getDay() + 6) % 7;
    let mondayTime = start.getTime() - offset * 86400000;
    return Math.floor((new Date().getTime() - mondayTime) / (7 * 86400000)) + 1;
  }

  pad2(value: number): string {
    return value < 10 ? `0${value}` : `${value}`;
  }

  dateText(date: Date): string {
    return `${date.getFullYear()}-${this.pad2(date.getMonth() + 1)}-${this.pad2(date.getDate())}`;
  }

  mondayTime(): number {
    let start = new Date(`${this.semesterStart}T00:00:00+08:00`);
    let offset = (start.getDay() + 6) % 7;
    return start.getTime() - offset * 86400000;
  }

  courseDate(weekDay: number): string {
    if (this.semesterStart.length === 0) {
      return '';
    }
    let day = this.mondayTime() + ((this.selectedWeek - 1) * 7 + (weekDay - 1)) * 86400000;
    return this.dateText(new Date(day));
  }

  async loadTimetable(): Promise<void> {
    if (this.currentSemesterId.length === 0) {
      return;
    }
    this.loading = true;
    this.error = '';
    try {
      this.items = await CampusApi.timetables(this.currentSemesterId, this.selectedWeek);
      let max = 5;
      for (let i = 0; i < this.items.length; i++) {
        if (this.items[i].end_period > max) {
          max = this.items[i].end_period;
        }
      }
      this.maxPeriod = max;
    } catch (e) {
      let message = '课表加载失败';
      if (e instanceof ApiException) {
        message = e.message;
      }
      this.error = message;
      promptAction.showToast({ message: message });
    } finally {
      this.loading = false;
    }
  }

  onSemesterSelect(index: number): void {
    if (index === this.selectedSemesterIndex) {
      return;
    }
    this.selectedSemesterIndex = index;
    let current = this.semesters[index];
    this.currentSemesterId = current.id;
    this.semesterStart = current.start_date;
    this.weekOptions = [];
    for (let i = 1; i <= current.week_count; i++) {
      this.weekOptions.push(new SelectOptionItem(`第${i}周`));
    }
    this.selectedWeek = 1;
    this.loadTimetable();
  }

  onWeekSelect(index: number): void {
    this.selectedWeek = index + 1;
    this.loadTimetable();
  }

  backToToday(): void {
    let current = this.semesters[this.selectedSemesterIndex];
    let week = this.currentWeek(current.start_date);
    if (week < 1) {
      week = 1;
    }
    if (week > current.week_count) {
      week = current.week_count;
    }
    this.selectedWeek = week;
    this.loadTimetable();
  }

  periodRows(): string {
    let parts: string[] = [];
    for (let i = 0; i < this.maxPeriod; i++) {
      parts.push('56vp');
    }
    return parts.join(' ');
  }

  colorFor(courseId: string): string {
    let n = parseInt(courseId);
    if (Number.isNaN(n)) {
      n = 0;
    }
    return this.courseColors[n % this.courseColors.length];
  }

  timeText(value: string): string {
    if (value.length >= 5) {
      return value.substring(0, 5);
    }
    return value;
  }

  dayList(): number[] {
    return [1, 2, 3, 4, 5, 6, 7];
  }

  periodList(): number[] {
    let list: number[] = [];
    for (let i = 1; i <= this.maxPeriod; i++) {
      list.push(i);
    }
    return list;
  }

  findCourse(period: number, day: number): TimetableItem | undefined {
    for (let i = 0; i < this.items.length; i++) {
      let item = this.items[i];
      if (item.week_day === day && item.start_period <= period && item.end_period >= period) {
        return item;
      }
    }
    return undefined;
  }

  courseName(period: number, day: number): string {
    let course = this.findCourse(period, day);
    return course === undefined ? '' : course.course_name;
  }

  courseRoom(period: number, day: number): string {
    let course = this.findCourse(period, day);
    return course === undefined ? '' : course.room_name;
  }

  courseTime(period: number, day: number): string {
    let course = this.findCourse(period, day);
    return course === undefined ? '' : `${this.timeText(course.start_time)}-${this.timeText(course.end_time)}`;
  }

  courseColor(period: number, day: number): string {
    let course = this.findCourse(period, day);
    return course === undefined ? AppTheme.COLOR_CARD : this.colorFor(course.course_id);
  }

  @Builder
  courseCell(period: number, day: number) {
    if (this.findCourse(period, day) !== undefined) {
      Column({ space: 2 }) {
        Text(this.courseName(period, day))
          .fontSize(12)
          .fontWeight(FontWeight.Medium)
          .fontColor(AppTheme.COLOR_TEXT_PRIMARY)
          .maxLines(2)
        Text(this.courseRoom(period, day))
          .fontSize(10)
          .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
          .maxLines(1)
        Text(this.courseTime(period, day))
          .fontSize(10)
          .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
      }
      .layoutWeight(1)
      .height(56)
      .padding(4)
      .borderRadius(6)
      .backgroundColor(this.courseColor(period, day))
      .border({ width: 0.5, color: AppTheme.COLOR_BORDER })
    } else {
      Column()
        .layoutWeight(1)
        .height(56)
        .backgroundColor(AppTheme.COLOR_CARD)
        .border({ width: 0.5, color: AppTheme.COLOR_BORDER })
    }
  }

  build() {
    Scroll() {
      Column({ space: AppTheme.SPACE_SECTION }) {
        if (this.semesterOptions.length > 0) {
          Column({ space: 10 }) {
            Row({ space: 8 }) {
              Text('学期')
                .width(46)
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
              Select(this.semesterOptions)
                .selected(this.selectedSemesterIndex)
                .value(this.semesterOptions[this.selectedSemesterIndex].value)
                .layoutWeight(1)
                .onSelect((index: number) => {
                  this.onSemesterSelect(index);
                })
            }
            .width('100%')

            Row({ space: 8 }) {
              Text('周次')
                .width(46)
                .fontSize(AppTheme.FONT_BODY)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
              Select(this.weekOptions)
                .selected(this.selectedWeek - 1)
                .value(this.weekOptions[this.selectedWeek - 1].value)
                .layoutWeight(1)
                .onSelect((index: number) => {
                  this.onWeekSelect(index);
                })
            }
            .width('100%')

            Button('返回当日课表')
              .width('100%')
              .height(38)
              .fontSize(AppTheme.FONT_BODY)
              .backgroundColor(AppTheme.COLOR_PRIMARY)
              .onClick(() => {
                this.backToToday();
              })
          }
          .padding(AppTheme.SPACE_SECTION)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }

        Text(`今天是 ${this.todayText}`)
          .fontSize(AppTheme.FONT_CAPTION)
          .fontColor(AppTheme.COLOR_PRIMARY)
          .width('100%')

        if (this.error.length > 0) {
          Column({ space: 10 }) {
            Text(this.error)
              .fontSize(AppTheme.FONT_BODY)
              .fontColor(AppTheme.COLOR_DANGER)
            Button('重新加载')
              .height(36)
              .onClick(() => {
                this.loadSemesters();
              })
          }
          .padding(AppTheme.SPACE_ITEM)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        } else if (this.loading) {
          Text('加载中...')
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
        } else if (this.items.length === 0) {
          Text('本周暂无课程')
            .fontSize(AppTheme.FONT_BODY)
            .fontColor(AppTheme.COLOR_TEXT_TERTIARY)
        } else {
          Column({ space: 0 }) {
            Row() {
              Text('节次')
                .width(48)
                .textAlign(TextAlign.Center)
                .fontSize(AppTheme.FONT_CAPTION)
                .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
              ForEach(this.dayList(), (day: number) => {
                Column({ space: 2 }) {
                  Text(`周${day}`)
                    .fontSize(AppTheme.FONT_CAPTION)
                    .fontColor(AppTheme.COLOR_TEXT_SECONDARY)
                  Text(this.courseDate(day))
                    .fontSize(10)
                    .fontColor(AppTheme.COLOR_TEXT_TERTIARY)
                }
                .layoutWeight(1)
                .alignItems(HorizontalAlign.Center)
              }, (day: number) => `${day}`)
            }
            .width('100%')
            .height(42)

            ForEach(this.periodList(), (period: number) => {
              Row() {
                Text(`第${period}节`)
                  .width(48)
                  .textAlign(TextAlign.Center)
                  .fontSize(10)
                  .fontColor(AppTheme.COLOR_TEXT_SECONDARY)

                ForEach(this.dayList(), (day: number) => {
                  this.courseCell(period, day)
                }, (day: number) => `${day}`)
              }
              .width('100%')
              .height(56)
            }, (period: number) => `${period}`)
          }
          .padding(AppTheme.SPACE_ITEM)
          .width('100%')
          .borderRadius(AppTheme.RADIUS_CARD)
          .backgroundColor(AppTheme.COLOR_CARD)
        }
      }
      .padding(AppTheme.SPACE_PAGE)
      .width('100%')
      .justifyContent(FlexAlign.Start)
      .alignItems(HorizontalAlign.Start)
      .backgroundColor(AppTheme.COLOR_BACKGROUND)
      .onAppear(() => {
        this.loadSemesters();
      })
    }
    .width('100%')
    .height('100%')
    .backgroundColor(AppTheme.COLOR_BACKGROUND)
  }
}
