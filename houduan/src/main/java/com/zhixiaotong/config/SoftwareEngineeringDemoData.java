package com.zhixiaotong.config;

import static com.zhixiaotong.common.Data.*;
import static com.zhixiaotong.common.BizException.check;
import com.zhixiaotong.common.*;
import com.zhixiaotong.security.Crypto;
import com.zhixiaotong.service.ScheduleValidator;
import java.time.*;
import java.util.*;
import org.springframework.boot.*;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Profile;
import org.springframework.core.annotation.Order;
import org.springframework.stereotype.Component;
import org.springframework.transaction.annotation.Transactional;

/** 显式启用的大学软件工程虚构演示数据。原子导入、一次性标记，不覆盖已有记录。 */
@Component
@Profile("demo")
@Order(10)
@ConditionalOnProperty(name="campus.software-demo-seed", havingValue="true")
public class SoftwareEngineeringDemoData implements ApplicationRunner {
  private final Db db;
  private final ScheduleValidator schedules;
  public SoftwareEngineeringDemoData(Db db, ScheduleValidator schedules) { this.db=db; this.schedules=schedules; }

  @Override @Transactional
  public void run(ApplicationArguments args) {
    var teacher = db.one("SELECT * FROM `user` WHERE user_name='teacher_demo'");
    check(teacher != null, 409, "请先初始化基础 demo 数据");
    long teacherId=num(teacher.get("id")), dept=num(teacher.get("org_id"));
    db.lock("user", teacherId);
    if (db.one("SELECT id FROM org_unit WHERE org_code='SE_DEMO_2026'") != null) return;
    var sem=db.one("SELECT * FROM semester WHERE is_current=1");
    check(sem != null && integer(sem,"is_locked",0)==0,409,"需要未锁定的当前学期");
    long semester=num(sem.get("id"));
    long major=db.insert("org_unit",map("parent_id",dept,"org_code","SE_DEMO_2026","org_name","软件工程（本科演示）","org_type",3));
    long grade=db.insert("org_unit",map("parent_id",major,"org_code","SE_GRADE_2026","org_name","2026级","org_type",4));
    long studentRole=num(db.one("SELECT id FROM role WHERE role_code='STUDENT'").get("id"));
    long teacherRole=num(db.one("SELECT id FROM role WHERE role_code='TEACHER'").get("id"));
    long counselor=num(db.one("SELECT id FROM `user` WHERE user_name='counselor_demo'").get("id"));
    List<Long> students=new ArrayList<>();
    // 让原三个演示学生也能联调课表/作业/签到；不改他们已有的身份、选课或成绩。
    for (String name:List.of("student_demo","student_two","student_other"))
      students.add(num(db.one("SELECT id FROM `user` WHERE user_name=?",name).get("id")));
    String[] names={"林晨","陈思远","周子涵","许嘉宁","宋知行","沈亦凡","陆明轩","程雨桐","苏沐言","顾星辰","叶清和","唐景然",
      "何书瑶","罗一诺","邵安宁","江承宇","魏可欣","夏思齐","袁柏舟","蔡若溪","方逸航","姚心悦","孟予安","贺言初"};
    for(int group=0;group<2;group++) {
      long cls=db.insert("school_class",map("class_code","SE2026_0"+(group+1),"class_name","软件工程2026级"+(group+1)+"班（演示）", "grade_id",grade,"entry_year",2026,"school_years",4));
      db.insert("counselor_class",map("counselor_id",counselor,"class_id",cls,"start_time",now().minusDays(1)));
      for(int j=0;j<12;j++) {
        int index=group*12+j;
        students.add(user(String.format("se_student_%02d",index+1),"示例·"+names[index],grade,cls,studentRole));
      }
    }
    long[] teachers={teacherId,user("se_teacher_01","示例·陈老师",dept,null,teacherRole),user("se_teacher_02","示例·宋老师",dept,null,teacherRole)};
    long[] rooms=new long[4];
    for(int i=0;i<4;i++) rooms[i]=db.insert("classroom",map("room_code","SE_LAB_"+(i+1),"room_name","软件工程实验室"+(i+1),"campus_name","主校区","building_name","软件工程实训楼","capacity",60));
    long batch=db.insert("selection_batch",map("batch_code","SE2026_ELECTIVE","batch_name","软件工程专业拓展选修（演示）","semester_id",semester,
      "batch_stage",3,"start_time",now().minusDays(1),"end_time",now().plusDays(30),"drop_deadline",now().plusDays(30),"max_courses",12,"max_credits",40,"batch_status",1,
      "announcement","虚构教学数据。已导入六门必修演示课，余下两门可测试选课；不代表真实教务记录。"));
    String[] courses={"面向对象程序设计","数据结构与算法","数据库系统原理","软件需求工程","软件体系结构","软件测试与质量保证","移动应用开发","软件项目管理"};
    String[] work={"设计图书借阅领域模型与Java类","实现二叉搜索树并分析复杂度","设计选课系统ER图与规范化表结构","编写校园系统需求规格说明","设计分层架构及接口契约","编写边界值和等价类测试用例","实现课程列表与详情页面","编写迭代计划与风险登记册"};
    List<Map<String,Object>> planned=new ArrayList<>();
    var existingStudentTimes=db.list("SELECT t.* FROM timetable t JOIN teaching_class tc ON tc.id=t.teaching_class_id JOIN enrollment e ON e.teaching_class_id=tc.id JOIN `user` u ON u.id=e.student_id WHERE tc.semester_id=? AND e.enroll_status=1 AND u.user_name IN ('student_demo','student_two','student_other')",semester);
    for(int i=0;i<courses.length;i++) {
      long owner=i<6?teachers[0]:teachers[i-5];
      long c=db.insert("course",map("course_code","SE26_C"+(i+1),"course_name",courses[i],"org_id",dept,"course_type",i<6?"专业必修":"专业选修","credit",3,"total_hours",48,"syllabus",work[i]+"。课程数据仅用于软件工程项目演示。"));
      long tc=db.insert("teaching_class",map("class_code","SE26_T"+(i+1),"course_id",c,"semester_id",semester,"teacher_id",owner,"class_name",courses[i]+"·2026本科演示班","capacity",50));
      Map<String,Object> chosen=null;
      for(int offset=0;offset<20 && chosen==null;offset++) {
        int day=(i+offset)%5+1,slot=(i+offset)/5%4;
        LocalTime start=List.of(LocalTime.of(10,40),LocalTime.of(14,0),LocalTime.of(15,50),LocalTime.of(19,0)).get(slot);
        var row=map("teaching_class_id",tc,"classroom_id",rooms[i%4],"start_week",1,"end_week",integer(sem,"week_count",20),"week_mode",1,"week_day",day,"start_period",3+slot*2,"end_period",4+slot*2,"start_time",start,"end_time",start.plusMinutes(90));
        if(planned.stream().anyMatch(p->ScheduleValidator.overlap(p,row)) || existingStudentTimes.stream().anyMatch(p->ScheduleValidator.overlap(p,row))) continue;
        try { schedules.validate(row,null); chosen=row; } catch(BizException conflict) { if(conflict.status!=409) throw conflict; }
      }
      check(chosen!=null,409,"演示课找不到无冲突时段，导入已回滚");
      db.insert("timetable",chosen); planned.add(chosen);
      long bc=db.insert("batch_course",map("batch_id",batch,"teaching_class_id",tc));
      db.insert("selection_scope",map("batch_course_id",bc,"org_id",dept,"include_children",1));
      List<Long> enrolled=new ArrayList<>();
      if(i<6) for(long s:students) {
        schedules.studentConflict(s,tc);
        long e=db.insert("enrollment",map("student_id",s,"teaching_class_id",tc,"request_key","SE26_REQUIRED_"+s+"_"+tc,"enroll_status",1,"enroll_time",now(),"result_note","虚构本科必修课程演示导入"));
        enrolled.add(e);
        // 当前学期只有平时成绩草稿，不虚构已完成考试或通过审核的正式成绩。
        if(i<2) db.insert("grade",map("enrollment_id",e,"usual_score",75+(s%20),"grade_status",0,"operator_id",owner));
      }
      db.update("teaching_class",tc,map("enrolled_count",enrolled.size()));
      for(int n=0;n<3;n++) {
        long assignment=db.insert("assignment",map("teaching_class_id",tc,"teacher_id",owner,"assignment_title",courses[i]+"·实践任务"+(n+1),"content",work[i]+"；提交设计说明、实现思路和测试结果。（教学样例）","grading_rule","完整性40分、正确性40分、说明与测试20分","deadline",now().plusDays(7+n*7),"allow_late",1,"publish_status",1));
        if(i<6 && n==0) for(int j=0;j<8;j++) db.insert("submission",map("assignment_id",assignment,"student_id",students.get(j),"content","教学示例：已完成基础设计与测试说明，等待教师反馈。","submit_time",now(),"submit_status",0));
      }
    }
    for(int i=0;i<12;i++) {
      String title=i<8?courses[i]+"实验指导":List.of("Git团队协作实践","Linux开发基础","设计模式实训","毕业设计写作指导").get(i-8);
      long book=db.insert("book",map("book_code","SE26_BOOK_"+(i+1),"book_name",title+"（教学样例）","author","软件工程教学资料组","category_code","SOFTWARE_ENGINEERING","summary","虚构馆藏，用于展示专业学习资料与预约功能，不冒用真实ISBN。"));
      for(int j=0;j<3;j++) db.insert("book_copy",map("book_id",book,"copy_no","SE26_COPY_"+i+"_"+j,"location","图书馆三楼软件工程专区"));
    }
    String[] notices={"软件工程专业实验室使用指引","课程设计提交规范","Git协作与代码评审实践周","软件测试实训安排","软件工程专业选修课说明"};
    for(int i=0;i<notices.length;i++) {
      long notice=db.insert("notice",map("notice_title",notices[i]+"（演示）","content","本通知为虚构教学样例：请按课程要求完成实验准备、团队分工与阶段报告。详情以任课教师实际安排为准。","publisher_id",teacherId,"start_time",now().minusMinutes(1),"publish_time",now(),"publish_status",1));
      db.insert("notice_scope",map("notice_id",notice,"scope_type",2,"org_id",dept,"include_children",1));
      long msg=db.insert("message",map("message_title",notices[i]+"（演示）","content","软件工程演示资料已更新，请在校园通知查看。","notice_id",notice,"biz_type","notice","biz_id",notice,"event_key","SE26_NOTICE_"+i));
      var recipients=new HashSet<Long>(students); for(long t:teachers)recipients.add(t);
      for(String name:List.of("counselor_demo","secretary_demo","dean_demo","admin_demo")) recipients.add(num(db.one("SELECT id FROM `user` WHERE user_name=?",name).get("id")));
      for(long recipient:recipients) db.insert("message_receipt",map("message_id",msg,"receiver_id",recipient,"delivery_status",1,"delivered_time",now()));
    }
  }
  private long user(String account,String name,long org,Long cls,long role) {
    long id=db.insert("user",map("user_name",account,"real_name",name,"user_no","SE26_"+account,"password_hash",Crypto.password("Demo@123456"),"email",account+"@example.edu","org_id",org,"class_id",cls));
    db.insert("user_role",map("user_id",id,"role_id",role)); return id;
  }
}
