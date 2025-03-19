-- SET statement_timeout = 0;
-- SET lock_timeout = 0;
-- SET idle_in_transaction_session_timeout = 0;
-- SET client_encoding = 'UTF8';
-- SET standard_conforming_strings = on;
-- SELECT pg_catalog.set_config('search_path', '', false);
-- SET check_function_bodies = false;
-- SET xmloption = content;
-- SET client_min_messages = warning;
-- SET row_security = off;
SET TIMEZONE='Asia/Taipei';

-- 使用 catimeta 資料庫
\c catimeta;

-- 讀取環境變數中的內容
\set schema `echo $SCHEMA`


-- 根據環境變數建立schema
CREATE SCHEMA IF NOT EXISTS :schema;



-- SET search_path TO dev, public;

-- 命名原則：
--  1. table名稱用複數，例如`projects`而非`project`。
--  2. column名稱則視其意義選用單數或複數，例如`name`, `total_dials`。
--  3. `notes`(備註)依一般表格慣例用複數，而`description`可為不可數名詞故用單數。
--  4. table的PK(primary key)一律稱`id`。
--  5. 除`id`外，如有自訂編號(含題號、答案代碼等)，稱`..._cid`(custom id)，如`project_cid`, `quota_cid`, `user_qst_cid`。
--  6. 已有較固定譯名者沿用之，如`extension_number`, `vat_number`等。
--  7. BOOLEAN型別欄位原則上有三種名命方式：
       7-1. `is_` + 形容詞或名詞，表示某種「狀態」，如`is_readonly`。
       7-2. `has_` + 名詞，表示是否擁有某個物件，如`has_image`。
            `has_` + 動詞的過去分詞，表示某事是否已完成，如`has_completed`。這個用法其實和`is_`差別不大，亦可作`is_completed`(其實如講究grammatical correct，應作`has_been_completed`)。
       7-3. `can_` + 動詞，表示可不可以做某事, 如`can_vote`。
       7-4. `should_` + 動詞，表示建議做或不做某事,如`should_refresh`。
       7-5. `must_` + 動詞，表示強制做或不做某事, 如`must_change_password`。
--  8. constraint的命名：
--     FK(foreign key): `fk_<子table名>_<父table名>`，如`fk_employees_companies`
--  9. index的命名：
--     1) 一般index: `idx_<table名>_<column名>`，如`idx_questionnaires_version`
--     2) GIN index : `gin_<table名>_<column名>，如`gin_results_answers`
-- 10. view的命名：
--    `v_<description>`，如`v_int_performancere`。

-- Create schema
-- CREATE SCHEMA dev;


-- 公司(drop existing table first)
DROP TABLE IF EXISTS :schema.companies CASCADE;
-- Recreate the :schema.companies table
CREATE TABLE :schema.companies (
    id         smallserial PRIMARY KEY,
    name       varchar(100) NOT NULL,
    in_charge  varchar(50),
    title      varchar(50),
    vat_number varchar(10),
    tel        varchar(30),
    fax        varchar(30),
    email      varchar(50),
    address    varchar(200),
    url        varchar(100),
    created_at timestamp with time zone DEFAULT now(),
    status     varchar(50),
    is_active  boolean,
    notes      text
);
COMMENT ON TABLE :schema.companies IS '公司資料表';

COMMENT ON COLUMN :schema.companies.id         IS '系統自動累加的id';
COMMENT ON COLUMN :schema.companies.name       IS '名稱';
COMMENT ON COLUMN :schema.companies.in_charge  IS '公司負責人';
COMMENT ON COLUMN :schema.companies.title      IS '負責人職稱';
COMMENT ON COLUMN :schema.companies.vat_number IS '統一編號';
COMMENT ON COLUMN :schema.companies.tel        IS '電話';
COMMENT ON COLUMN :schema.companies.fax        IS '傳真';
COMMENT ON COLUMN :schema.companies.email      IS '電郵';
COMMENT ON COLUMN :schema.companies.address    IS '地址';
COMMENT ON COLUMN :schema.companies.url        IS '網址';
COMMENT ON COLUMN :schema.companies.created_at IS '建立日期';
COMMENT ON COLUMN :schema.companies.status     IS '狀態';
COMMENT ON COLUMN :schema.companies.is_active  IS '是否啟用';
COMMENT ON COLUMN :schema.companies.notes      IS '備註';

COMMENT ON INDEX :schema.companies_pkey IS '公司table的PK索引，由系統自動建立';

-- Insert data into :schema.companies
INSERT INTO :schema.companies (name, in_charge, title, vat_number, tel, fax, email, address, url, status, is_active, notes) VALUES
('智晟資訊服務股份有限公司', '楊雲榮', '總經理', '85002520', '02-25068916#210', '02-25065610', 'yunjung@iactor.com.tw', '台北市中山區建國北路2段86號12樓', '', '', true, ''),
('輿智資通科技股份有限公司', '楊雲榮', '總經理', '29054237', '02-25068916', '', '', '台北市中山區建國北路2段86號12樓', '', '', true, ''),
('博聞民調公司', '', '', '', '', '', '', '', '', '', true, ''),
('中華民國民意測驗協會', '溫博仕', '秘書長', '', '', '', '', '', '', '', true, ''),
('聯邦行銷股份有限公司', 'Alex Van', '董事長', '', '', '', '', '', '', '', true, '');

-- 客戶(drop existing table first)
DROP TABLE IF EXISTS :schema.clients CASCADE;
-- Recreate the :schema.clients table
CREATE TABLE :schema.clients (
    id           serial PRIMARY KEY,
    client_cid   varchar(15),
    name         varchar(60),
    gender       char(1),
    title        varchar(50),
    company_name varchar(50),
    company_unit varchar(50),
    contact      varchar(100),
    vat_number   varchar(10),
    tel          varchar(30),
    cell         varchar(20),
    fax          varchar(30),
    email        varchar(50),
    address      varchar(200),
    created_at   timestamp with time zone DEFAULT now(),
    status       varchar(50),
    is_active    boolean DEFAULT true,
    notes        text
);
COMMENT ON TABLE :schema.clients IS '客戶(委託者)資料表';

COMMENT ON COLUMN :schema.clients.id           IS '系統自動累加的id';
COMMENT ON COLUMN :schema.clients.client_cid   IS '自訂客戶編號';
COMMENT ON COLUMN :schema.clients.name         IS '姓名';
COMMENT ON COLUMN :schema.clients.gender       IS '性別';
COMMENT ON COLUMN :schema.clients.title        IS '職稱';
COMMENT ON COLUMN :schema.clients.company_name IS '公司名稱';
COMMENT ON COLUMN :schema.clients.company_unit IS '單位名稱';
COMMENT ON COLUMN :schema.clients.contact      IS '聯絡人';
COMMENT ON COLUMN :schema.clients.vat_number   IS '統一編號';
COMMENT ON COLUMN :schema.clients.tel          IS '電話';
COMMENT ON COLUMN :schema.clients.cell         IS '手機';
COMMENT ON COLUMN :schema.clients.fax          IS '傳真';
COMMENT ON COLUMN :schema.clients.email        IS '電郵';
COMMENT ON COLUMN :schema.clients.address      IS '地址';
COMMENT ON COLUMN :schema.clients.created_at   IS '建立時間';
COMMENT ON COLUMN :schema.clients.status       IS '狀態';
COMMENT ON COLUMN :schema.clients.is_active    IS '是否啟用';
COMMENT ON COLUMN :schema.clients.notes        IS '備註';

DROP INDEX IF EXISTS idx_clients_client_cid;
CREATE INDEX idx_clients_client_cid ON :schema.clients(client_cid);
COMMENT ON INDEX :schema.idx_clients_client_cid IS '自訂客戶編號索引';
COMMENT ON INDEX :schema.clients_pkey           IS '客戶table的PK索引，由系統自動建立';

-- Insert data into :schema.clients
INSERT INTO :schema.clients (client_cid, family_name, given_name, gender, title, company_name, company_unit, contact, vat_number, tel, cell, fax, email, address, status, notes) VALUES
('A00001', '鄧', '碧雲', 'F', '研究員', '新北市ABC博物館', '研發部', '', '', '02-74523008#3701', '0918-652417', '02-74523008#3723', 'dave.lin@abcmuseum.com', '新北市板橋區縣民大道2段100號3樓', '', ''),
('D00004', '張', '瑛', 'M', '科長', '台北市交通局', '第二科', '', '', '02-3654258#506', '0932-125890', '02-3654258#508', 'yingchang@tra.gov.tw', '台北市大安區安和路1段152號4樓', '', '老客戶'),
('T00001', '曹', '達華', 'M', '經理', '八角亭公司', '服務中心', '王小姐', '03524189', '02-66320140', '0921-520236', '02-66321029', 'cdh@octcorner.com.tw', '台北市文山區木柵2段66號1樓', '', '聯法公司介紹'),
('T00005', '張', '活游', 'M', '董事長特助', '全影公司', '公關部', '', '23651028', '02-56879204', '0912-320147', '02-56870049', 'nicetrip@parabc.com', '台北市中山區松江路367號7樓', '', ''),
('T00007', '陳', '寶珠', 'F', '主任', '海角遊雲公司', '廣告部', '', '36521077', '02-42124589', '0921-236989', '02-42125018', 'pearlchan@seecorner.com', '台北市松山區八德路4段692號4樓', '', ''),
('A00021', '關', '德興', 'M', '專員', '桃園市政府社會局', '第三科', '', '', '03-3322101', '0914-541236', '03-3322756', 'she3.taoyuan.gov.tw', '桃園市桃園區縣府路1號3、4、8樓', '', ''),
('A00012', '蕭', '芳芳', 'F', '副館長', '台北市立圖書館', '採編課', '張先生', '', '02-74102035', '0932-874512', '02-74100236', 'josephine-siao@email.tpml.edu.tw', '台北市建國南路二段125號', '', '老客戶'),
('C00001', '白', '燕', 'F', '社工師', '萬芳醫院', '社工課', '', '', '02-56874412', '0926-125470', '02-56892177', 'bayin@wanfang.gov.tw', '台北市文山區興隆路三段111號', '', ''),
('F00036', '余', '麗珍', 'F', '組長', 'Momo購物網', '市場調查組', '劉先生', '45210299', '02-74120239', '0920-365126', '02-74136562', 'info@momo.com.tw', '台北市內湖區洲子街96號4樓', '', ''),
('B00049', '梅', '綺', 'F', '秘書', 'PChome', '行銷處', '郭先生', '56541783', '02-33245120', '0914-741020', '02-33342120', 'cherrylee@pchome.com.tw', '台北市大安區敦化南路二段105號15樓', '', '王者公司介紹'),
('E00001', '于', '素秋', 'F', '總裁特助', '亞太集團', '物流中心', '陳小姐', '12570395', '02-35269874', '0919-325894', '02-35269878', 'judyyu@newasian.com', '台北市大安區新生南路2段86號5樓', '', '新興公司介紹'),
('S00008', '吳', '楚帆', 'M', '副處長', '江氏企業', '總管理處', '李小姐', '08532107', '02-52369017', '0925-411238', '02-52360775', 'john.ng@kongs.com', '台北市信義區福德街86號7樓', '', '業佳公司介紹');


-- 員工(drop existing table first)
DROP TABLE IF EXISTS :schema.employees CASCADE;
-- Recreate the :schema.employees table
CREATE TABLE :schema.employees (
    id                serial PRIMARY KEY,
    company_id        smallint,
    employee_cid      varchar(30),
    name              varchar(50) NOT NULL,
    password          varchar(1024) NOT NULL,
    department        varchar(50),
    extension_number  varchar(8),
    title             varchar(20),
    role              varchar(10),
    gender            char(1),
    dob               date,
    edu               varchar(150),
    idcard            varchar(20),
    cell              varchar(20),
    email             varchar(50),
    household_address varchar(200),
    current_address   varchar(200),
    joined_on         date,
    created_at        timestamp with time zone DEFAULT now(),
    status            varchar(50),
    is_active         boolean DEFAULT true,
    notes             text,
    CONSTRAINT fk_employees_companies
        FOREIGN KEY(company_id)
        REFERENCES :schema.companies(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.employees IS '員工資料表';

COMMENT ON COLUMN :schema.employees.id                IS '系統自動累加的id';
COMMENT ON COLUMN :schema.employees.company_id        IS '所屬公司id，為references `companies` table的foreign key';
COMMENT ON COLUMN :schema.employees.employee_cid      IS '自訂員工編號';
COMMENT ON COLUMN :schema.employees.name              IS '姓名';
COMMENT ON COLUMN :schema.employees.password          IS '密碼';
COMMENT ON COLUMN :schema.employees.department        IS '部門';
COMMENT ON COLUMN :schema.employees.extension_number  IS '分機號碼';
COMMENT ON COLUMN :schema.employees.title             IS '職稱';
COMMENT ON COLUMN :schema.employees.role              IS '角色';
COMMENT ON COLUMN :schema.employees.gender            IS '性別';
COMMENT ON COLUMN :schema.employees.dob               IS '出生日期';
COMMENT ON COLUMN :schema.employees.edu               IS '教育程度';
COMMENT ON COLUMN :schema.employees.idcard            IS '身分證或其他證件';
COMMENT ON COLUMN :schema.employees.cell              IS '手機';
COMMENT ON COLUMN :schema.employees.email             IS '電郵';
COMMENT ON COLUMN :schema.employees.household_address IS '戶籍地址';
COMMENT ON COLUMN :schema.employees.current_address   IS '目前(通訊)地址';
COMMENT ON COLUMN :schema.employees.joined_on         IS '入職日期';
COMMENT ON COLUMN :schema.employees.created_at        IS '建立日期';
COMMENT ON COLUMN :schema.employees.status            IS '狀態';
COMMENT ON COLUMN :schema.employees.is_active         IS '是否在職';
COMMENT ON COLUMN :schema.employees.notes             IS '備註';

COMMENT ON INDEX :schema.employees_pkey IS '員工table，由系統自動建立的PK索引';

-- Insert data into :schema.employees
INSERT INTO :schema.employees (company_id, employee_cid, name, password, department, extension_number, title, role, gender, dob, edu, idcard, cell, email, household_address, current_address, joined_on, status, notes) VALUES
(1, 'A0001', '楊雲榮', '', '', '210', '總經理', 'admin', 'M', '1979-05-23', '', 'A105635897', '0933-029478', 'yunjung@iactor.com.tw', '', '', '2000-05-19', '', '創辦人'),
(2, 'B0001', '楊雲榮', '', '', '210', '總經理', 'admin', 'M', '1979-05-23', '', 'A105635897', '0933-029478', 'yunjung@iactor.com.tw', '', '', '2000-05-19', '', '創辦人'),
(1, 'A0004', '陳淑貞', '', '', '', '主任', '', 'F', null, '', 'D236014788', '0917-536973', 'janechen@iactor.com.tw', '', '', '2019-07-01', '', '民意測驗協會'),
(2, 'B0039', '陳淑貞', '', '', '', '資深研究員', '', 'F', null, '', 'D236014788', '0917-536973', 'janechen@iactor.com.tw', '', '', '2019-07-01', '', ''),
(1, 'A0006', '洪敏琛', '', '專案服務部', '212', '經理', '', 'M', null, '', 'F103652897', '0910-621606', 'lwy@iactor.com.tw', '', '', '2020-03-18', '', ''),
(2, 'B0046', '洪敏琛', '', '專案研究部', '212', '經理', '', 'M', null, '', 'F103652897', '0910-621606', 'lwy@iactor.com.tw', '', '', '2020-03-18', '', ''),
(1, 'A0010', '郭育成', '', '專案服務部', '235', '副理', '', 'M', null, '', 'J163027045', '0906-390871', 'kyc@iactor.com.tw', '', '', '2020-11-01', '', ''),
(3, 'C0105', '郭育成', '', '研發中心', '235', '資深副理', '', 'M', null, '', 'J163027045', '0906-390871', 'kyc@xyz.com.tw', '', '', '2020-11-05', '', ''),
(1, '102071558407030567164', 'Amos Tsai', '$2b$12$QZ/4TyHEqTLxJUCe2qfRiOU64BKN0/5iMEpiWKW9VYog0gQonjqHK', 'Division of Information', '500', 'CIO', 'admin', 'M', null, '', 'F104531381', '0927-320142', 'amos.tsai@iactgor.com.tw', '', '', '2023-09-26', '', ''),
(1, 'A0101', 'Alex Van',  '', 'Division of Information', '503', 'Senior Engineer', '', 'M', null, '', 'F120369808', '0918-800878', 'alexvan@iactgor.com.tw', '', '', '2023-09-26', '', '');


-- 訪員/督導(drop existing table first)
DROP TABLE IF EXISTS :schema.interviewers CASCADE;
-- Recreate the :schema.interviewers table
CREATE TABLE :schema.interviewers (
    id                    serial PRIMARY KEY,
    interviewer_cid       varchar(12) NOT NULL UNIQUE,
    company_id            smallint,
    family_name           varchar(50) NOT NULL,
    given_name            varchar(50) NOT NULL,
    grade                 varchar(12),
    role                  varchar(10),
    gender                char(1),
    dob                   date,
    edu                   varchar(150),
    idcard                varchar(20),
    tel                   varchar(30),
    cell                  varchar(20),
    email                 varchar(50),
    updates               varchar(50),
    available_periods     varchar(20)[],
    available_areas       varchar(20)[],
    household_address     varchar(200),
    current_address       varchar(200),
    languages             varchar(20)[],
    input_methods         varchar(20)[],
    account               varchar(20),
    must_pay_supp_prem    boolean,
    trained_on            date,
    joined_on             date,
    total_shifts          integer  DEFAULT 0 CHECK (total_shifts >= 0 AND total_shifts <= 100000),
    total_qres            integer  DEFAULT 0 CHECK (total_qres >= 0 AND total_qres <= 50000),
    total_questions       integer  DEFAULT 0 CHECK (total_questions >= 0 AND total_questions <= 250000000),
    longest_questionnaire smallint DEFAULT 0 CHECK (longest_questionnaire >= 0 AND longest_questionnaire <= 3000),
    highest_difficulty    smallint CHECK (highest_difficulty >= 1 AND highest_difficulty <= 10),
    total_dials           integer  DEFAULT 0 CHECK (total_dials >= 0 AND total_dials <= 30000000),
    total_completions     integer  DEFAULT 0 CHECK (total_completions >= 0 AND total_completions <= 4000000),
    total_refusals        integer  DEFAULT 0 CHECK (total_refusals >= 0 AND total_refusals <= 16000000),
    total_hwses           smallint CHECK (total_hwses >= 0 AND total_hwses <= 30000),
    last_shift_on         date,
    last_hws_on           date,
    created_at            timestamp with time zone DEFAULT now(),
    status                varchar(50),
    is_active             boolean DEFAULT true,
    notes                 text,
    CONSTRAINT fk_interviewers_companies
        FOREIGN KEY(company_id)
        REFERENCES :schema.companies(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.interviewers IS '訪員資料表';

COMMENT ON COLUMN :schema.interviewers.id                    IS '系統自動累加的id';
COMMENT ON COLUMN :schema.interviewers.interviewer_cid       IS '自訂訪員編號';
COMMENT ON COLUMN :schema.interviewers.company_id            IS '所屬公司id，為references `companies` table的foreign key';
COMMENT ON COLUMN :schema.interviewers.family_name           IS '姓';
COMMENT ON COLUMN :schema.interviewers.given_name            IS '名';
COMMENT ON COLUMN :schema.interviewers.grade                 IS '級別';
COMMENT ON COLUMN :schema.interviewers.role                  IS '角色';
COMMENT ON COLUMN :schema.interviewers.gender                IS '性別';
COMMENT ON COLUMN :schema.interviewers.dob                   IS '出生日期';
COMMENT ON COLUMN :schema.interviewers.edu                   IS '教育程度';
COMMENT ON COLUMN :schema.interviewers.idcard                IS '身分證或其他證件';
COMMENT ON COLUMN :schema.interviewers.tel                   IS '室內電話';
COMMENT ON COLUMN :schema.interviewers.cell                  IS '手機';
COMMENT ON COLUMN :schema.interviewers.email                 IS '電郵';
COMMENT ON COLUMN :schema.interviewers.updates               IS '動態(如最近能來日期...等)';
COMMENT ON COLUMN :schema.interviewers.available_periods     IS '可工作時段(可複選，如上午、下午、晚上...)';
COMMENT ON COLUMN :schema.interviewers.available_areas       IS '可工作地區(可複選，如台北市、新北市雙和一帶、南彰化、屏東縣北部...等)';
COMMENT ON COLUMN :schema.interviewers.household_address     IS '戶籍(永久)地址';
COMMENT ON COLUMN :schema.interviewers.current_address       IS '目前(通訊)地址';
COMMENT ON COLUMN :schema.interviewers.languages             IS '語言(可複選)';
COMMENT ON COLUMN :schema.interviewers.input_methods         IS '慣用輸入法(可複選)';
COMMENT ON COLUMN :schema.interviewers.account               IS '金融帳號';
COMMENT ON COLUMN :schema.interviewers.must_pay_supp_prem    IS '是否須繳健保補充費';
COMMENT ON COLUMN :schema.interviewers.trained_on            IS '職前訓練日期';
COMMENT ON COLUMN :schema.interviewers.joined_on             IS '入職日期';
COMMENT ON COLUMN :schema.interviewers.total_shifts          IS '累計：總上班次(天)數';
COMMENT ON COLUMN :schema.interviewers.total_qres            IS '累計：總問卷數';
COMMENT ON COLUMN :schema.interviewers.total_questions       IS '累計：總問過題數';
COMMENT ON COLUMN :schema.interviewers.longest_questionnaire IS '累計：問過的最長問卷題數';
COMMENT ON COLUMN :schema.interviewers.highest_difficulty    IS '累計：問過的最難問卷的難度(範圍1-10)';
COMMENT ON COLUMN :schema.interviewers.total_dials           IS '累計：總撥號數';
COMMENT ON COLUMN :schema.interviewers.total_completions     IS '累計：總完成數';
COMMENT ON COLUMN :schema.interviewers.total_refusals        IS '累計：總拒訪數';
COMMENT ON COLUMN :schema.interviewers.total_hwses           IS '累計：執行戶內抽樣次數';
COMMENT ON COLUMN :schema.interviewers.last_shift_on         IS '最後上班日期';
COMMENT ON COLUMN :schema.interviewers.last_hws_on           IS '最後執行戶內抽樣日期';
COMMENT ON COLUMN :schema.interviewers.created_at            IS '建立日期';
COMMENT ON COLUMN :schema.interviewers.status                IS '狀態';
COMMENT ON COLUMN :schema.interviewers.is_active             IS '是否在職';
COMMENT ON COLUMN :schema.interviewers.notes                 IS '備註';


DROP INDEX IF EXISTS idx_interviewers_interviewer_cid;
CREATE INDEX idx_interviewers_interviewer_cid ON :schema.interviewers(interviewer_cid);
COMMENT ON INDEX :schema.idx_interviewers_interviewer_cid IS '自訂訪員編號索引';
COMMENT ON INDEX :schema.interviewers_pkey IS '訪員table的PK索引，由系統自動建立';

-- Insert data into :schema.interviewers
INSERT INTO :schema.interviewers (interviewer_cid, company_id, family_name, given_name, grade, role, gender, dob, edu, idcard, tel, cell, email, updates, available_periods, available_areas, household_address, current_address, languages, input_methods, account, must_pay_supp_prem, trained_on, joined_on, total_shifts, total_qres, total_questions, longest_questionnaire, highest_difficulty, total_dials, total_completions, total_refusals, total_hwses, last_shift_on, last_hws_on, status, notes) VALUES
('0001', 1, '譚', '蘭卿', 'A', '訪員', 'F', null, '', '', '02-22362501', '0917-825602', 'tamlanhing@gmail.com', '白天下班較晚，7:00pm才能到', ARRAY['下午', '晚上'], ARRAY['台北市', '新店', '雙和'], '台南市山上區...', '台北市文山區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '', false, '2023-01-17', '2023-01-20', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-04-04', '2023-07-08', '', ''),
('0002', 1, '黃', '曼梨', 'B', '訪員', 'F', null, '', '', '02-54212306', '0937-541526', 'marywong@gmail.com', '以白天為主，晚上要看情形', ARRAY['上午', '下午'], ARRAY['台北市', '新北市', '基隆'], '花蓮縣花蓮市...', '台北市大安區...', ARRAY['國語', '閩南語'], ARRAY['倉頡', '注音'], '', false, '2022-08-30', '2022-08-30', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-04-01', '2024-04-01', '', ''),
('0003', 1, '高', '魯泉', 'A', '訪員', 'M', null, '', '', '02-32014780', '0923-639826', 'koulou@gmail.com', '搭公車時不幸摔傷腳，請假至2024-05', ARRAY['上午', '下午', '晚上'], ARRAY['桃園市', '新竹縣市'], '新北市永和區...', '台北市信義區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '', true, '2023-04-06', '2023-04-08', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-03-25', '2023-12-20', '', ''),
('0004', 1, '陳', '立品', 'E', '督導', 'F', null, '', '', '02-23698027', '0922-532104', 'lapbun@gmail.com', '', ARRAY['晚上'], ARRAY['台北市', '新店', '雙和', '板橋'], '台中市豐原區...', '台北市內湖區...', ARRAY['國語', '閩南語', '客語'], ARRAY['漢語拼音'], '', true, '2001-06-11', '2001-06-12', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-04-04', '2024-04-04', '', ''),
('0005', 1, '鄭', '君綿', 'B', '訪員', 'M', null, '', '', '02-75201281', '0918-652078', 'kunmin@gmail.com', '', ARRAY['晚上'], ARRAY['台南市'], '台南市永康區...', '台北市南港區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '', true, '2022-01-12', '2022-01-19', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-02-15', '2024-01-12', '', ''),
('0006', 2, '馬', '笑英', 'A', '訪員', 'F', null, '', '', '02-22341209', '0915-741026', 'smilingma@gmail.com', '生病，休息至2024-06', ARRAY['上午', '下午', '晚上'], ARRAY['高雄市', '北屏東', '南台南'], '台南市關廟區...', '新北市中和區...', ARRAY['國語', '閩南語'], ARRAY['注音', '大易'], '', false, '2022-12-27', '2022-12-31', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-04-02', '2023-11-25', '', ''),
('0007', 1, '周', '志誠', 'C', '訪員', 'M', null, '', '', '02-32147175', '0910-962106', 'chising@gmail.com', '周末不來', ARRAY['下午', '晚上'], ARRAY['苗栗縣以北'], '新竹縣湖口鄉...', '台北市北投區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '319-1254789652304', true, '2021-06-30', '2021-07-12', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-03-11', '2023-12-14', '', ''),
('0008', 1, '馮', '應湘', 'E', '督導', 'M', null, '', '', '02-23652108', '0919-801478', 'yingsiung@gmail.com', '', ARRAY['晚上'], ARRAY['台東縣', '花蓮縣'], '澎湖縣馬公市...', '台北市松山區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '', false, '2020-02-22', '2020-03-01', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-01-30', '2024-01-30', '', ''),
('0009', 2, '李', '月清', 'D', '訪員', 'F', null, '', '', '02-25891414', '0924-782102', 'moonlee@gmail.com', '最近不行', ARRAY['上午', '晚上'], ARRAY['宜蘭縣', '基隆市'], '雲林縣西螺鎮...', '台北市中正區...', ARRAY['國語', '閩南語', '英語'], ARRAY['注音'], '503-58796214586307', true, '2018-03-10', '2018-04-04', 0, 0, 0, 0, null, 0, 0, 0, 0, '2023-09-09', '2022-10-08', '', ''),
('0010', 2, '梁', '淑卿', 'B', '訪員', 'F', null, '', '', '02-32321457', '0914-852100', 'shuhing@gmail.com', '周二和周四不行', ARRAY['下午', '晚上'], ARRAY['台北市東區', '新北市汐止區', '新北市林口區', '新北市瑞芳區'], '高雄市左營區...', '台北市士林區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '', true, '2023-06-13', '2023-06-13', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-02-25', '2023-11-27', '', ''),
('0011', 3, '司馬', '華龍', 'A', '訪員', 'M', null, '', '', '02-25859412', '0920-521471', 'simahualung@gmail.com', '', ARRAY['上午', '下午', '晚上'], ARRAY['台北市', '新北市', '桃園市'], '台北市大安區...', '台北市大安區...', ARRAY['國語', '閩南語', '粵語'], ARRAY['嘸蝦米', '注音'], '', false, '2021-08-03', '2021-08-16', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-04-01', '2023-11-27', '', ''),
('0012', 3, '歐陽', '儉', 'C', '訪員', 'M', null, '', '', '02-85201049', '0915-852369', 'ouyangkim@gmail.com', '', ARRAY['下午', '晚上'], ARRAY['嘉義縣市', '雲林縣', '台南市', '南投縣'], '台東縣池上鄉...', '新北市三重區...', ARRAY['國語', '閩南語'], ARRAY['倉頡'], '', true, '2022-10-07', '2022-10-08', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-01-12', '2023-11-27', '', ''),
('0013', 1, '容', '玉意', 'C', '訪員', 'F', null, '', '', '02-35024589', '0916-874120', 'yungyukyi@gmail.com', '', ARRAY['下午', '晚上'], ARRAY['金門'], '金門縣金城鎮...', '金門縣金城鎮...', ARRAY['國語', '閩南語'], ARRAY['大易', '漢語拼音'], '', true, '2019-08-04', '2019-08-16', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-02-28', '2024-01-13', '', ''),
('0014', 1, '任', '冰兒', 'B', '訪員', 'F', null, '', '', '02-7741239', '0920-036217', 'yambingyi@gmail.com', '整天都有空，周末也可配合', ARRAY['上午', '下午', '晚上'], ARRAY['台中市', '南投縣'], '台東縣池上鄉...', '新北市三重區...', ARRAY['國語', '閩南語'], ARRAY['注音'], '812-52369874102470', false, '2019-08-04', '2019-08-06', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-05-22', '2024-02-25', '', ''),
('0015', 2, '葉', '萍', 'D', '訪員', 'F', null, '', '', '02-22039804', '0918-200176', 'yipping@gmail.com', '平常下班很晚，只有周末和假日才能來', ARRAY['周末', '假日'], ARRAY['北北基', '桃園', '新竹'], '桃園市中壢區...', '桃園市平鎮區...', ARRAY['國語', '閩南語', '客語'], ARRAY['注音', '嘸蝦米'], '', true, '2019-08-04', '2019-08-05', 0, 0, 0, 0, null, 0, 0, 0, 0, '2024-06-30', '2024-03-10', '', '');


-- 專案(drop existing table first)
DROP TABLE IF EXISTS :schema.projects CASCADE;
-- Recreate the :schema.projects table
CREATE TABLE :schema.projects (
    id                 serial PRIMARY KEY,
    parent_project_cid varchar(50),
    client_id          integer,
    company_id         smallint,
    pm_id              integer,
    auth_empl_ids      jsonb,
    project_cid        varchar(50) NOT NULL unique,
    name               varchar(300) NOT NULL,
    description        varchar(500),
    qre_active_version smallint DEFAULT 0 CHECK (qre_active_version >= 0),
    difficulty         smallint CHECK (difficulty >= 1 AND difficulty <= 10),
    type               varchar(50) CHECK (status IN ('N', 'P', 'C', 'X', 'S', 'O')),
    completions_now    integer CHECK (completions_now >= 0 AND completions_now <= 200000),
    refusals_now       integer CHECK (refusals_now >= 0 AND refusals_now <= 500000),
    scheduled_on       date,
    due_on             date,
    started_on         date,
    ended_on           date,
    tags               varchar(50)[],
    created_at         timestamp with time zone DEFAULT now(),
    status             varchar(20) CHECK (status IN ('N', 'P', 'C', 'X', 'S', 'O')),
    is_active          boolean,
    notes              text,
    CONSTRAINT fk_projects_projects
        FOREIGN KEY(parent_project_cid)
        REFERENCES :schema.projects(project_cid)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_projects_clients
        FOREIGN KEY(client_id)
        REFERENCES :schema.clients(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_projects_companies
        FOREIGN KEY(company_id)
        REFERENCES :schema.companies(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_projects_employees
        FOREIGN KEY(pm_id)
        REFERENCES :schema.employees(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.projects IS '專案表';

COMMENT ON COLUMN :schema.projects.id                 IS '系統自動累加的id';
COMMENT ON COLUMN :schema.projects.parent_project_cid IS '父專案的cid';
COMMENT ON COLUMN :schema.projects.client_id          IS '客戶(委託者)id，為references `clients` table的foreign key';
COMMENT ON COLUMN :schema.projects.company_id         IS '接案公司id，為references `companies` table的foreign key';
COMMENT ON COLUMN :schema.projects.pm_id              IS '專案負責人(PM)id，為references `employees` table的foreign key';
COMMENT ON COLUMN :schema.projects.auth_empl_ids      IS '其他有權限員工的ids';
COMMENT ON COLUMN :schema.projects.project_cid        IS '自訂編號';
COMMENT ON COLUMN :schema.projects.name               IS '專案名稱';
COMMENT ON COLUMN :schema.projects.description        IS '專案詳細說明';
COMMENT ON COLUMN :schema.projects.qre_active_version IS '問卷現行版本(含相關設定)';
COMMENT ON COLUMN :schema.projects.difficulty         IS '難度';
COMMENT ON COLUMN :schema.projects.type               IS '類型(如"一般"、"不統計訪員數據"、"面訪key-in"、"代客key-in"...) {"N": "未開始(Not Started)", "P": "進行中(In Progress)", "C": "面訪key-in", "X": "不統計訪員績效", "S": "代客key-in", "O": "其他(Others)"}';
COMMENT ON COLUMN :schema.projects.completions_now    IS '目前完成人數';
COMMENT ON COLUMN :schema.projects.refusals_now       IS '目前拒訪人數';
COMMENT ON COLUMN :schema.projects.scheduled_on       IS '預定開始日期';
COMMENT ON COLUMN :schema.projects.due_on             IS '預定結束日期';
COMMENT ON COLUMN :schema.projects.started_on         IS '實際開始日期';
COMMENT ON COLUMN :schema.projects.ended_on           IS '實際結束日期';
COMMENT ON COLUMN :schema.projects.tags               IS '標籤';
COMMENT ON COLUMN :schema.projects.created_at         IS '建立時間';
COMMENT ON COLUMN :schema.projects.status             IS '狀態 {"N": "未開始(Not Started)", "P": "進行中(In Progress)", "C": "已完成(Completed)", "X": "已取消(Cancelled)", "S": "暫停(Suspended)", "O": "其他(Others)"}';
COMMENT ON COLUMN :schema.projects.is_active          IS '是否啟用';
COMMENT ON COLUMN :schema.projects.notes              IS '備註';

DROP INDEX IF EXISTS idx_projects_parent_project_cid;
CREATE INDEX idx_projects_parent_project_cid ON :schema.projects(parent_project_cid);
DROP INDEX IF EXISTS idx_projects_client_id;
CREATE INDEX idx_projects_client_id          ON :schema.projects(client_id);
COMMENT ON INDEX :schema.idx_projects_parent_project_cid IS '父專案索引';
COMMENT ON INDEX :schema.idx_projects_client_id          IS '客戶索引';
COMMENT ON INDEX :schema.projects_pkey                   IS '專案table的PK索引，由系統自動建立';

-- Insert data into :schema.projects
INSERT INTO :schema.projects (parent_project_cid, client_id, company_id, pm_id, auth_empl_ids, project_cid, name, description, qre_active_version, difficulty, type, completions_now, refusals_now, scheduled_on, due_on, started_on, ended_on, tags, status, is_active, notes) VALUES
(null, 2, 1, 3, $${"ee_ids": [5, 7, 10]}$$, '2024A0001', '台灣大學109學年度(110年)畢業滿3年學生流向追蹤調查', '本項調查結果將提供母校辦學及校務發展改善、系所學位學程課程規劃及高等教育人才培育等相關政策研議之參考。', '全球民調公司', 1, 4, '一般', 5630, 1451, '2024-07-01', '2024-09-30', '2024-07-10', null, ARRAY['畢業', '校友', '台大', '學生'], 'P', true, 'AAAA'),
(null, 8, 1, 7,    $${"ee_ids": [5, 3, 10]}$$, '2024A0002', '交通工具調查', '為瞭解民眾日常外出運具使用情形，並推估我國公共運輸市占率，作為交通部公共運輸計畫之啟動基礎與成效評估輔助指標，以掌握一全國統整性運輸概況資訊...', '全球民調公司', 1, 3, '一般', 0, 0, '2024-10-01', '2024-11-20', null, null, ARRAY['交通', '駕駛人', '行人', '交通工具', '運具', '交通事故'], 'N', true, 'BBBB'),
(null, 1, 1, 5, $${"ee_ids": [7]}$$, '2024A0003', '北部私立大學學生對學校設備滿意度調查', '做為使用者與受教者的學生，對於學校所提供的整體教育環境的滿意程度如何？不同類型院校的學生對學校的滿意度有何異同？', '新世界民調公司', null, null, '一般', null, null, '2024-05-25', '2024-05-30', null, null, ARRAY['私立大學', '設備', '學生', '評鑑'], null, true, 'CCCC'),
('2024A0003', 1, 1, 3, $${"ee_ids": [5, 7, 10]}$$, '2024A0003-1', '北部私立大學學生對學校設備滿意度調查--世新大學', 'bbbbbbb', '新世界民調公司', 1, 5, '一般', 2370, 269, '2024-07-10', '2024-09-30', '2024-07-29', null, ARRAY['私立大學', '設備', '世新', '世新大學', '學生', '評鑑'], 'P', true, 'DDDD'),
('2024A0003', 1, 1, 5, $${"ee_ids": [3, 7, 10]}$$, '2024A0003-2', '北部私立大學學生對學校設備滿意度調查--輔仁大學', 'ccccccc', '新世界民調公司', 2, 5, '一般', 2305, 308, '2024-06-10', '2024-08-25', '2024-06-12', '2024-08-28', ARRAY['私立大學', '設備', '輔大', '輔仁大學', '學生', '評鑑'], 'C', true, 'QQQQ'),
('2024A0003', 1, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0003-3', '北部私立大學學生對學校設備滿意度調查--文化大學', 'dddddd', '新世界民調公司', 1, 5, '一般', 0, 0, '2024-10-06', '2024-12-22', null, null, ARRAY['私立大學', '設備', '文大', '文化大學', '學生', '評鑑'], 'N', true, 'WWWW'),
(null, 3, 2, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0004', '民眾日常使用運具狀況調查', '交通部於民國 98 年創辦「民眾日常使用運具狀況調查」，按年進行綜觀國人整體外出旅次目的、起訖點、時段及選搭運具種類等多元資訊之全國性調查...', '國家政策與民意學會', 3, 2, '一般', 1861, 2108, '2024-06-10', '2024-06-30', '2024-06-05', '2024-06-19', ARRAY['運具', '交通', '行人', '公路'], 'C', true, 'EEEE'),
(null, 4, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0005', '2024國人運動習慣調查', '為瞭解全民運動推展各項政策的執行情形，教育部體育署委託世新大學進行「運動現況調查」，今(18)日公布去(112)年運動現況調查成果，國人參與運動人口比例達82.6%，規律運動人口比例自103年以來，首度達到35.0%（規律運動7333定義：每週運動3次以上；每次運動30分鐘以上；運動時會流汗也會喘）。', '智晟', 4, 4, '一般', 0, 0, '2024-05-15', '2024-05-22', null, null, ARRAY['運動', '習慣', '健康', '快樂', '生活'], 'X', true, 'RRRR'),
(null, 10, 3, 3, $${"ee_ids": [5, 7, 10, 9]}$$, '2024A0006', '113年環島路線、多元路線調查', '近年來，政府推動自行車旅遊活動已有顯著成效，尤其在98-101年推動「東部自行車路網示範計畫」及104-107 年推動的「全國自行車友善環境路網整體規劃及交通部自行車路網建置計畫」後，自行車觀光旅遊活動已蔚為風潮。', '智晟', 5, 3, '一般', 0, 0, '2024-11-10', '2024-11-30', null, null, ARRAY['環島', '路線', '公路', '駕駛'], 'N', true, 'TTTT'),
(null, 5, 4, 3, $${"ee_ids": [5, 7]}$$, '2024A0007', '台北市交通局施政滿意度調查', '臺北市政府交通局為瞭解臺北市民眾對於交通局各項交通施政、交通改善 情形與意向，作為施政決策參考，特辦理113年臺北市交通民意調查。', '智晟', 6, 4, '一般', 0, 0, '2024-05-15', '2024-05-22', null, null, ARRAY['施政', '滿意度', '法規', '統計', '預算', '道路', '交通安全'], 'X', true, 'YYYY'),
(null, 4, 3, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0008', '台北市動物園遊客調查', '經過近二十年的發展，動物園的教育理念由「愛護動物」推衍至「尊重各式各樣的生命」；教育的內容也由單純的「動物」擴及「植物」、「棲地保護」乃至珍惜所有有形、無形的如水、能源等「自然資源」。', '四方民調', 5, 3, '一般', 863, 744, '2024-06-10', '2024-06-30', '2024-06-09', '2024-06-21', ARRAY['動物園', '交通', '貓纜', '捷運', '親子'], 'C', true, 'UUUU'),
(null, 11, 5, 3, $${"ee_ids": [5, 7]}$$, '2024A0009', '南投縣休閒農場調查', '南投休閒農場擁有寬敞的園區，更享有絕佳的自然景緻，不但可以遠眺中央山脈、集集大山、九九峰、合歡山，清晨更可以180度的遼闊視野觀賞日出美景，渾圓的太陽隨著時序乍現，金黃的璀璨光芒穿透山景，讓繾綣繚繞的純白雲海映上一層光彩，美得令人張口讚嘆！', '五行政策研究中心', 2, 4, '一般', 0, 0, '2024-10-15', '2024-10-22', null, null, ARRAY['休閒', '農埸', '預算', '負評'], 'N', true, 'IIII'),
(null, 7, 2, 3, $${"ee_ids": [5, 10, 9]}$$, '2024A0010', '2024數位落差調查', '數位落差（英語：digital divide，中國大陸作數字鴻溝，香港作數碼鴻溝，又稱數碼隔閡、數碼隔膜或數碼差距等）是指社會上不同性別、種族、經濟、居住環境、階級背景的人，接近使用數位產品（如電腦或是網路）的機會與能力上的差異。', '政大陳百齡教授', null, null, '一般', 1366, 1904, '2024-06-10', '2024-06-30', null, null, ARRAY['數位', '落差', '數位落差', '弱勢', '電腦', '平板'], null, true, 'OOOO'),
('2024A0010', 7, 2, 3, $${"ee_ids": [5, 7, 10, 9]}$$, '2024A0010-1', '2024數位落差調查--一般民眾', '數位落差是指社會上不同性別、種族、經濟、居住環境、階級背景的人，接近使用數位產品的機會與能力上的差異。', '政大陳百齡教授', 5, 6, '一般', 1366, 1904, '2024-09-03', '2024-09-21', '2024-09-06', null, ARRAY['數位', '落差', '電腦', '平板'], 'P', true, 'PPPP'),
('2024A0010', 7, 2, 3, $${"ee_ids": [5, 7]}$$, '2024A0010-2', '2024數位落差調查--偏鄉', '數位落差是指社會上不同性別、種族、經濟、居住環境、階級背景的人，接近使用數位產品的機會與能力上的差異。', '政大陳百齡教授', 3, 7, '一般', 0, 0, '2024-09-28', '2024-10-06', null, null, ARRAY['數位', '落差', '電腦', '平板', '偏鄉'], 'N', true, ';;;;'),
('2024A0010', 7, 2, 3, $${"ee_ids": [5, 7]}$$, '2024A0010-3', '2024數位落差調查--身心障礙', '數位落差是指社會上不同性別、種族、經濟、居住環境、階級背景的人，接近使用數位產品的機會與能力上的差異。', '政大陳百齡教授', 4, 8, '一般', 0, 0, '2024-10-15', '2024-10-30', null, null, ARRAY['數位', '落差', '電腦', '手機', '身障', '心障', '身心障礙'], 'N', true, '::::'),
(null, 6, 3, 3, $${"ee_ids": [5, 7]}$$, '2024A0011', '青少年使用手機狀況調查', '隨著科技的日新月異，人與人之間的聯繫越來越便捷，而標榜「溝通零距離」的行動電話逐漸普及之後，台灣社會幾乎「人手一機」，尤其，電信業者看準國內兒童手機市場的龐大商機，紛紛鎖定家有孩童的現代爸媽，以各式廣告強力放送，大力鼓吹孩子使用手機的種種好處和必要性。', '中華民國民意測驗協會', 1, 6, '一般', 752, 1903, '2024-05-15', '2024-05-22', '2024-05-15', null, ARRAY['青少年', '手機', '課業', '宅', '社交媒體', '詐騙'], 'S', true, '!!!!'),
(null, 8, 2, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0012', '消費者網購行為調查', '後疫情時代帶來全球消費模式的轉變，宅經濟的興起讓消費者越趨於習慣網購，實體通路亦面臨轉型挑戰，不僅維持線下營運同步也得另闢拓展線上整合。', '知行民調公司', 2, 4, '一般', 959, 1130, '2024-06-10', '2024-06-30', '2024-06-07', '2024-06-21', ARRAY['網購', '網路', '實體', '平台', '詐騙'], 'C', true, '@@@@'),
(null, 9, 5, 5, $${"ee_ids": [7]}$$, '2024A0013', '台北市捷運滿意度調查', '台北捷運在國際競爭力上有多項優勢，截至目前為止，112年系統營運可靠度（MKBF）達1,846萬車廂公里，創下通車以來最佳表現，各路線準點率均突破99％，旅客滿意度高達96.7％，品牌滿意度相當卓越。', '智晟', 6, 4, '一般', 5033, 7885, '2024-05-15', '2024-05-22', '2024-05-15', '2024-05-22', ARRAY['台北市', '捷運', '路線', '尖峰', '滿意度'], 'C', true, '####'),
(null, 6, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0014', '2024國人閱讀習慣調查', '讓書成為人一生的夥伴，伴隨生涯前進的步伐飄香讓書成為人靈性的伴侶，成長的路上隨時指引幫助無論閱讀、閱聽、閱覽，喜歡了就一直讀下去...', '快樂民調公司', 4, 2, '一般', 256, 414, '2024-05-15', '2024-05-22', null, null, ARRAY['閱讀', '圖書', '借閱', '圖書館'], 'S', true, '$$$$'),
(null, 10, 2, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0015', '新北市自行車專用道路使用情形調查', '本市境內自行車道可分為運輸型及遊憩型。遊憩型多為河濱自行車道；另運輸型自行車道依本市道路特性多規劃人車共道或一般車道混用型式，透過通勤綠廊規劃，結合雙鐵(捷運及自行車)轉乘，整合運輸型及遊憩型自行車道，以提升整體交通串連服務。', '民意調查中心', 5, 3, '一般', 911, 952, '2024-06-10', '2024-06-30', '2024-06-12', '2024-06-25', ARRAY['新北市', '自行車', '專用道路', '路線', '行人', '車輛'], 'C', true, 'hhhhh'),
(null, 5, 1, 7, $${"ee_ids": [5, 3]}$$, '2024A0016', '世界各國國民快樂指數調查', '世界幸福報告（英語：World Happiness Report）為聯合國為衡量幸福的可持續發展方案，於網路出版的國際調查報告。', '西北大學民意研究中心', 3, 4, '一般', 820, 1365, '2024-05-17', '2024-05-22', '2024-05-16', '2024-05-20', ARRAY['快樂', '指數', '滿足', '跨國'], 'C', true, 'jyhg'),
(null, 6, 3, 3, $${"ee_ids": [5, 7]}$$, '2024A0017', '社交媒體依賴度調查', '社交媒體在我們生活中扮演了非常重要的角色，那麼我們會不會為此犧牲了心理健康、身體健康，並浪費了時間？相關證據表明了什麼？', '中山大學社會所黃麗莉老師', 8, 5, '一般', 0, 0, '2024-05-15', '2024-05-22', null, null, ARRAY['社交媒體', '依賴度', '詐騙', '成癮'], 'S', true, '&&&&'),
(null, 8, 2, 3, $${"ee_ids": [5]}$$, '2024A0018', '2024年中華民國總統選舉調查', '依據中華民國法規，投票日前10日（台灣標準時間2024年1月3日00:00）起到投票時間截止前（台灣標準時間2024年1月13日16:00）不得發布、報導、散布、評論、引述民意調查資料。', '時代趨勢公司', null, null, '一般', 0, 0, '2024-05-15', '2024-05-22', null, null, ARRAY['選舉', '總統大選', '投票', '施政'], null, true, '****'),
('2024A0018', 8, 2, 3, $${"ee_ids": [5, 7, 10, 9]}$$, '2024A0018-1', '2024年中華民國總統選舉調查--市話', '2024總統選舉電話訪問--市話', '時代趨勢公司', 5, 7, '一般', 1073, 2884, '2023-11-01', '2023-11-16', '2023-11-01', '2023-11-14', ARRAY['總統', '選舉', '投票', '2024', '市話'], 'C', true, '????'),
('2024A0018', 8, 2, 3, $${"ee_ids": [5, 7, 10, 9]}$$, '2024A0018-2', '2024年中華民國總統選舉調查--手機', '2024總統選舉電話訪問--手機', '時代趨勢公司', 3, 8, '一般', 755, 2309, '2023-11-05', '2024-11-25', '2023-11-05', '2023-11-20', ARRAY['總統', '選舉', '投票', '2024', '手機'], 'C', true, 'MMMM'),
('2024A0018', 8, 2, 3, $${"ee_ids": [5, 10, 9]}$$, '2024A0018-3', '2024年中華民國總統選舉調查--網路', '2024總統選舉網路調查', '時代趨勢公司', 4, 7, '一般', 3239, 4502, '2023-11-05', '2024-11-15', '2023-11-03', '2023-11-10', ARRAY['總統', '選舉', '投票', '2024', '網路'], 'C', true, 'NNNN'),
('2024A0018', 8, 2, 3, $${"ee_ids": [7, 10, 9]}$$, '2024A0018-4', '2024年中華民國總統選舉調查--街訪', '2024總統選舉街頭訪問', '時代趨勢公司', 1, 8, '一般', 616, 1937, '2023-11-10', '2024-11-29', '2023-11-10', '2023-12-03', ARRAY['總統', '選舉', '投票', '2024', '街訪'], 'C', true, 'BBBB'),
('2024A0018', 8, 2, 3, $${"ee_ids": [5, 7, 10]}$$, '2024A0018-5', '2024年中華民國總統選舉調查--到府', '2024總統選舉到府訪問', '時代趨勢公司', 2, 9, '一般', 520, 3465, '2023-11-15', '2024-12-02', '2023-11-15', '2023-12-01', ARRAY['總統', '選舉', '投票', '2024', '到府'], 'C', true, 'KKKK'),
(null, 6, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0019', '海運服務業對我國港埠作業滿意度調查', '瞭解民眾與海運服務業者對交通部所屬各機關(構)各項服務之滿意度及對交通施政措施之看法，作為考評服務績效及研訂相關政策之重要參據。', '智晟', 1, 3, '一般', 125, 288, '2024-05-15', '2024-05-22', '2024-05-17', null, ARRAY['海運', '運輸', '服務業', '港埠', '滿意度', '貨運'], 'X', true, 'CCCC'),
(null, 3, 2, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0020', '台北市兒童新樂園滿意度調查', '前身位於圓山的「台北市立兒童育樂中心」現已搬遷到士林區，並改名為「台北市立兒童新樂園」。台北市立兒童新樂園是台灣一座受歡迎的兒童親子樂園，提供各種豐富多樣的遊樂 ...', '智晟', 2, 2, '一般', 0, 0, '2024-11-10', '2024-11-30', null, null, ARRAY['兒童樂園', '設施', '星光', '親子', '滿意度'], 'N', true, 'XXXX'),
(null, 12, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0021', '2024交通部公路局交通量調查', '調查的範圍不含臺北市及高雄市，為公路局管轄的省道及代養縣道公路系統，包含快速道路；還有省道通過省轄市區的路段。', '智晟', 1, 3, '一般', 98, 71, '2024-05-15', '2024-05-22', null, null, ARRAY['2024', '交通', '公路局', '車輛', '危險路段'], 'X', true, 'ZZZZ'),
(null, 6, 1, 5, $${"ee_ids": [3, 7]}$$, '2024A0022', '外勞仲介公司服務品質調查', '調查採用分層隨機抽樣原則，分別由各私立就業服務機構的企業及家庭客戶中抽出代表樣本後，再進行電話或實地訪問。；', '智晟', null, null, '一般', 36416, 6723, '2024-07-15', '2024-09-30', null, null, ARRAY['外勞', '仲介', '企業', '漁船', '雇主', '服務', '費用'], null, true, 'HHHH'),
('2024A0022', 6, 1, 5, $${"ee_ids": [3, 7]}$$, '2024A0022-1', '外勞仲介公司服務品質調查--企業雇主', '調查採用分層隨機抽樣原則，分別由各私立就業服務機構的企業及家庭客戶中抽出代表樣本後，再進行電話或實地訪問。；', '智晟', 3, 5, '一般', 5480, 3733, '2024-07-25', '2024-09-12', '2024-07-29', null, ARRAY['外勞', '仲介', '企業', '漁船', '雇主', '服務', '費用'], 'P', true, 'SSSS'),
('2024A0022', 6, 1, 5, $${"ee_ids": [3, 7]}$$, '2024A0022-2', '外勞仲介公司服務品質調查--企業外勞', '調查採用分層隨機抽樣原則，分別由各私立就業服務機構的企業及家庭客戶中抽出代表樣本後，再進行電話或實地訪問。；', '智晟', 2, 6, '一般', 23504, 0, '2024-08-01', '2024-09-28', '2024-08-19', null, ARRAY['外勞', '仲介', '企業', '漁船', '雇主', '服務', '費用'], 'P', true, 'ASWRF'),
('2024A0022', 6, 1, 5, $${"ee_ids": [7]}$$, '2024A0022-3', '外勞仲介公司服務品質調查--家庭雇主', '調查採用分層隨機抽樣原則，分別由各私立就業服務機構的企業及家庭客戶中抽出代表樣本後，再進行電話或實地訪問。；', '智晟', 4, 4, '一般', 3716, 2990, '2024-07-15', '2024-08-10', '2024-07-10', '2024-08-03', ARRAY['外勞', '仲介', '家庭', '家戶', '雇主', '服務', '費用'], 'C', true, 'P;LOYU'),
('2024A0022', 6, 1, 5, $${"ee_ids": [7]}$$, '2024A0022-4', '外勞仲介公司服務品質調查--家庭外勞', '調查採用分層隨機抽樣原則，分別由各私立就業服務機構的企業及家庭客戶中抽出代表樣本後，再進行電話或實地訪問。；', '智晟', 1, 5, '一般', 3716, 0, '2024-07-15', '2024-08-10', '2024-07-10', '2024-08-11', ARRAY['外勞', '仲介', '雇主', '服務', '費用'], 'C', true, 'CDXS'),
(null, 4, 1, 3, $${"ee_ids": [5, 7]}$$, '2024A0023', '桃園市社會福利實施情形滿意度調查', '台灣民間社福機構與政府之間多數伴隨著社會福利服務委託外包的合作關係，民間社福機構為因應委託契約續約的不確定性，衍生出社工員的工作期限與委託契約期限掛鉤的現象。', '成功行銷研究公司', 7, 5, '一般', 1241, 1007, '2024-05-15', '2024-05-22', null, null, ARRAY['社會福利', '滿意度', '獨居長者', '身心障礙', '中低收入', '弱勢'], 'C', true, '..8596741..'),
(null, 11, 3, 7, $${"ee_ids": [5, 3, 10, 9]}$$, '2024A0024', '2024年師大宿舍使用及滿意程度', '本研究旨在探討大專住宿生對學生宿舍期待與滿意度之現況，及希望了解有關的影響因素，以作為仁德專校宿舍輔導工作改善的參考，提升學生住宿品質，加強宿舍之教育功能。', '多聞基金會', 1, 3, '一般', 0, 0, '2024-10-17', '2024-10-28', null, null, ARRAY['師大', '宿舍', '本部', '分部', '冷氣'], 'N', true, 'JJJJ'),
(null, 9, 4, 3, $${"ee_ids": [5, 7, 10, 9]}$$, '2024A0025', '雙北市民對治安滿意度調查', '內政部警政署為瞭解台北市和新北市民眾對於113年上半年治安及警察整體服務的感受度，作為規劃及改善治安政策之參考，於113年X月X日至Y月Y日期間辦理「民眾對治安滿意度調查」。', '智晟', null, null, '一般', 528, 1669, '2024-07-07', '2024-08-31', null, null, ARRAY['治安', '內政部', '警政署', '滿意度', '報案'], null, true, 'FFFF'),
('2024A0025', 9, 4, 3, $${"ee_ids": [7, 5, 10, 9]}$$, '2024A0025-1', '雙北市民對治安滿意度調查--台北市', '內政部警政署為瞭解台北市和新北市民眾對於113年上半年治安及警察整體服務的感受度，作為規劃及改善治安政策之參考，於113年X月X日至Y月Y日期間辦理「民眾對治安滿意度調查」。', '智晟', 4, 7, '一般', 528, 1669, '2024-09-07', '2024-09-20', '2024-09-08', null, ARRAY['治安', '內政部', '警政署', '滿意度', '報案'], 'P', true, '00986'),
('2024A0025', 9, 4, 3, $${"ee_ids": [9, 7, 10, 5]}$$, '2024A0025-2', '雙北市民對治安滿意度調查--新北市', '內政部警政署為瞭解台北市和新北市民眾對於113年上半年治安及警察整體服務的感受度，作為規劃及改善治安政策之參考，於113年X月X日至Y月Y日期間辦理「民眾對治安滿意度調查」。', '智晟', 6, 7, '一般', 0, 0, '2024-09-25', '2024-10-05', null, null, ARRAY['治安', '內政部', '警政署', '滿意度', '報案'], 'N', true, 'dddd');


-- --
---- 問卷(drop existing table first)
DROP TABLE IF EXISTS :schema.questionnaires CASCADE;
-- Recreate the :schema.questionnaires table
CREATE TABLE :schema.questionnaires (
    id                     serial PRIMARY KEY,
    project_id             integer NOT NULL,
    survey_method          char(1) DEFAULT 'W' CHECK (survey_method IN ('T', 'W', 'E', 'P', 'H', 'S')),
    name                   varchar(300),
    version                smallint NOT NULL,
    description            varchar(500),
    claimed_name           varchar(100),
    questions              jsonb NOT NULL,
    rules                  jsonb NOT NULL,
    -- is_whs_used            boolean,  -- 納入`rules`
    must_collect_int_stats boolean, -- 新增
    is_locked              boolean,
    is_readonly            boolean DEFAULT false,
    difficulty             smallint CHECK (difficulty >= 1 AND difficulty <= 10),
    type                   varchar(50),
    -- fore_color             char(7),   -- 納入`rules`
    -- back_color             char(7),   -- 納入`rules`
    completions_now    integer CHECK (completions_now >= 0 AND completions_now <= 200000),
    refusals_now       integer CHECK (refusals_now >= 0 AND refusals_now <= 500000),
    scheduled_on       date,
    due_on             date,
    started_on         date,
    ended_on           date,

    is_updating            boolean,
    is_up_to_date          boolean,
    tags                   varchar(50)[],
    created_at             timestamp with time zone DEFAULT now(),
    status                 varchar(20) CHECK (status IN ('N', 'P', 'C', 'X', 'S', 'O')),
    is_active              boolean,
    notes                  text,
    CONSTRAINT fk_questionnaires_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.questionnaires IS '問卷表';

COMMENT ON COLUMN :schema.questionnaires.id                     IS '系統自動累加的id';
COMMENT ON COLUMN :schema.questionnaires.project_id             IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.questionnaires.survey_method          IS '調查方法："T": 電話訪問  "W": 網路調查  "E": email調查  "P": 郵寄問卷  "H": 到府訪問  "S": 街頭訪問';
COMMENT ON COLUMN :schema.questionnaires.name                   IS '問卷名稱(主題)';
COMMENT ON COLUMN :schema.questionnaires.version                IS '問卷版本';
COMMENT ON COLUMN :schema.questionnaires.description            IS '版本名稱';
COMMENT ON COLUMN :schema.projects.claimed_name                 IS '對外宣稱的執行機構名稱';
COMMENT ON COLUMN :schema.questionnaires.questions              IS '各題題目(含選項)內容';
COMMENT ON COLUMN :schema.questionnaires.rules                  IS '控制問卷流程的各項邏輯和環境設定，例如標題顏色、戶內抽樣、題目形態、測量尺度、答案長度、答案範圍、答案個數、跳題、互斥、隨機、貼題...等';
-- COMMENT ON COLUMN :schema.questionnaires.is_whs_used   IS '是否採用戶內抽樣';
COMMENT ON COLUMN :schema.questionnaires.must_collect_int_stats IS '是否上鎖(上鎖後訪員無法進入)';
COMMENT ON COLUMN :schema.questionnaires.is_locked     IS '是否上鎖(上鎖後訪員無法進入)';
COMMENT ON COLUMN :schema.questionnaires.is_readonly   IS '是否唯讀(唯讀時不能更新版本)';
COMMENT ON COLUMN :schema.questionnaires.difficulty    IS '難度';
COMMENT ON COLUMN :schema.questionnaires.type          IS '類型(如"一般"、"不統計訪員數據"、"面訪key-in"、"代客key-in"...)';
-- COMMENT ON COLUMN :schema.questionnaires.fore_color    IS '(訪員程式中的標題等)前景色';
-- COMMENT ON COLUMN :schema.questionnaires.back_color    IS '(訪員程式中的標題等)背景色';
COMMENT ON COLUMN :schema.questionnaires.is_updating   IS '是否有在線上計算訪問結果以及訪員績效等';
COMMENT ON COLUMN :schema.questionnaires.is_readonly   IS '是否唯讀(唯讀時不能更新版本)';
COMMENT ON COLUMN :schema.questionnaires.difficulty    IS '難度';
COMMENT ON COLUMN :schema.questionnaires.type          IS '類型(如"一般"、"不統計訪員數據"、"面訪key-in"、"代客key-in"...)';
-- COMMENT ON COLUMN :schema.questionnaires.fore_color    IS '(訪員程式中的標題等)前景色';
-- COMMENT ON COLUMN :schema.questionnaires.back_color    IS '(訪員程式中的標題等)背景色';
COMMENT ON COLUMN :schema.questionnaires.is_updating   IS '是否有在線上計算訪問結果以及訪員績效等';
COMMENT ON COLUMN :schema.questionnaires.is_up_to_date IS '線上計算是否已和訪問同步(是否跟上訪問進度)';
COMMENT ON COLUMN :schema.questionnaires.tags          IS '標籤';
COMMENT ON COLUMN :schema.questionnaires.created_at    IS '建立時間';
COMMENT ON COLUMN :schema.questionnaires.status        IS '狀態 {"N": "未開始(Not Started)", "P": "進行中(In Progress)", "C": "已完成(Completed)", "X": "已取消(Cancelled)", "S": "暫停(Suspended)", "O": "其他(Others)"}';
COMMENT ON COLUMN :schema.questionnaires.is_active     IS '是否為目前使用版本';
COMMENT ON COLUMN :schema.questionnaires.notes         IS '備註';

DROP INDEX IF EXISTS idx_questionnaires_project_id;
CREATE INDEX idx_questionnaires_project_id ON :schema.questionnaires(project_id);
DROP INDEX IF EXISTS idx_questionnaires_version;
CREATE INDEX idx_questionnaires_version    ON :schema.questionnaires(version);
DROP INDEX IF EXISTS gin_questionnaires_questions;
CREATE INDEX gin_questionnaires_questions  ON :schema.questionnaires USING GIN (questions);
COMMENT ON INDEX :schema.idx_questionnaires_project_id IS '專案編號索引';
COMMENT ON INDEX :schema.idx_questionnaires_version    IS '問卷版本索引';
COMMENT ON INDEX :schema.gin_questionnaires_questions  IS '各題題目(jsonb)索引';
COMMENT ON INDEX :schema.questionnaires_pkey           IS '問卷table的PK索引，由系統自動建立';

-- Insert data into :schema.questionnaires
INSERT INTO :schema.questionnaires (project_id, survey_method, name, version, description, claimed_name, questions, rules, must_collect_int_stats, is_locked, is_readonly, difficulty, type, is_updating, is_up_to_date, tags, status, is_active, notes) VALUES
(1, 'W', '臺灣大學107學年度畢業滿5年學生流向追蹤調查', 1, 'initial version', $${"overview": {"qre_name": "臺灣大學107學年度畢業滿5年學生流向追蹤調查", "max_anses": 1, "min_anses": 1, "back_color": "", "fore_color": [""], "len_each_ans": 2, "num_sys_qsts": 47, "num_user_qsts": 46, "sys_qst_order": {"items": [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, 41, 42, 43, 44, 45, 46]}, "active_version": 1, "max_completions": 1, "min_completions": 1, "completion_threshold": 45}, "questions": [{"qst": "親愛的畢業校友，您好：<br><br>臺灣大學畢業滿五年的您，現況如何？母校十分關心您，希望瞭解您的現況與感想。本項調查結果將提供母校辦學及校務發展改善、系所學位學程課程規劃及高等教育人才培育等相關政策研議之參考。您的意見十分重要，懇請您耐心協助填答。若您認為不方便作答，可選擇不填答，並不會影響您任何權益，但請勿轉由他人代為填答。母校仍由衷希望您能撥冗回覆本調查。<br><br>本問卷結果將依個人資料保護法規定嚴密保管與遵循法令規定處理，並提供以下單位進行後續運用，以及避免重複向您蒐集資料，敬請放心填答。<br><br>  1.提供教育部進行教育政策研議與分析…等事項。<br>  2.提供學校辦理教學改進、服務追蹤、資訊交流及未來校友服務…等事項。<br><br>敬請儘速於收到網路填卷通知後１週內將問卷回填。如對本問卷填答有任何疑問或需依個人資料保護法第3條規定行使相關權利時，歡迎以E-Mail或電話與我們聯絡(調查研究中心電話：02-25164678) 。感謝您的填答！<br><br><div style='text-align: right;'>臺灣大學學生職業生涯發展中心    莊建隆先生 Tel：02-33662046</div><div style='text-align: right;'>智晟資訊服務股份有限公司    陳淑貞小姐 Tel：02-25164678</div><div style='text-align: right;'>民國113年6月</div>", "name": "", "skip": [], "type": "0", "table": {}, "is_zip": false, "ranges": [], "is_date": false, "is_time": false, "options": [], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 0, "is_narrative": true, "len_each_ans": 2, "render_table": false, "user_qst_cid": 0, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [], "num_opts_each_line": -1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１ 敬請核對您的姓名、學號、系所。如姓名、學號、系所有錯誤，請先聯絡學校。", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "03", "range_lo": "01"}, {"range_hi": "96", "range_lo": "96"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "修改手機: __________", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "修改市話: __________", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "修改email: __________ (如有兩個以上email帳號請以分號隔開)", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "96", "op_body": "不用改", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 3, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 1, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": ["96"], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請填寫正確的手機門號：", "txt_max_len": 20, "txt_min_len": 1, "txt_parent_ans": "01"}, {"txt_prompt": "請填寫正確的市話門號：", "txt_max_len": 20, "txt_min_len": 1, "txt_parent_ans": "02"}, {"txt_prompt": "請填寫正確的email(如有兩個以上email帳號請以分號隔開)：", "txt_max_len": 50, "txt_min_len": 1, "txt_parent_ans": "03"}], "post_qst_prompt": "<div style='font-size: 130%; color: Navy;'>姓名：<font color='Tomato'><b>@@__name__@@</b></font></font>　　　　　　在校學號：<font color='Tomato'><b>@@__sample_cid__@@</b></font>　　　　　　系所：<font color='Tomato'><b>@@__major__@@</b></font><br><br>並請更正聯絡電話及e-mail等資料，謝謝！<br>1.手機：<font color='Tomato'><b>@@__cell__@@</b></font>　　　　2.市話：<font color='Tomato'><b>@@__tel__@@</b></font>　　　　3.常用email：<font color='Tomato'><b>@@__email__@@</b></font></div>", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "修改手機: __________", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "修改市話: __________", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "修改email: __________(如有兩個以上email帳號請以分號隔開)", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "96", "op_body": "不用改", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２ 請問您目前狀況？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "12", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "已經就業,全職工作", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "已經就業,部份工時", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "未就業,國內外學校進修", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "未就業,國外打工遊學、就讀語文學校", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "未就業,服役/待役中", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "未就業,準備考試或出國進修深造", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "未就業,正在求職", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "未就業,家管/料理家務者", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "未就業,留職停薪/育嬰假", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "未就業,剛離職未投履歷", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "未就業,剛退伍未投履歷", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "未就業,剛畢業未投履歷", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "未就業,其他情形(如不想找工作、生病..),請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 2, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 2, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**若同時有全職工作與在學校進修學位，請以一週花費時間較多者為主，選擇已就業(全職工作) 或未就業(國內外學校進修) 之其中一項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "已經就業,全職工作", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "已經就業,部份工時", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "未就業,國內外學校進修", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "未就業,國外打工遊學、就讀語文學校", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "未就業,服役/待役中", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "未就業,準備考試或出國進修深造", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "未就業,正在求職", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "未就業,家管/料理家務者", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "未就業,留職停薪/育嬰假", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "未就業,剛離職未投履歷", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "未就業,剛退伍未投履歷", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "未就業,剛畢業未投履歷", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "未就業,其他情形(如不想找工作、生病..),請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３ 請問您一週工作時數平均約幾小時？", "name": "", "skip": [], "type": "3", "table": {}, "is_zip": false, "ranges": [{"range_hi": "140", "range_lo": "001"}], "is_date": false, "is_time": false, "options": [], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 3, "is_narrative": false, "len_each_ans": 3, "render_table": false, "user_qst_cid": 3, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**若兼職多份工作請填1週總工作時數_______小時", "original_options": [], "num_opts_each_line": -1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４ 請問在國內或國外的學校進修？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "國內", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "國外", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 4, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 4, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "國內", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "國外", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "５ 在國外那一個國家的學校進修﹖", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "27", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "韓國", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "日本", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新加坡", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "阿拉伯", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "澳洲", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "紐西蘭", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "英國", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "法國", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "荷蘭", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "丹麥", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "比利時", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "西班牙", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "德國", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "捷克", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "瑞士", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "奧地利", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "匈牙利", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "義大利", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "瑞典", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "芬蘭", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "波蘭", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "俄羅斯", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "加拿大", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "美國", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "97", "op_body": "請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 5, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 5, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "韓國", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "日本", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新加坡", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "阿拉伯", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "澳洲", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "紐西蘭", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "英國", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "法國", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "荷蘭", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "丹麥", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "比利時", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "西班牙", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "德國", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "捷克", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "瑞士", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "奧地利", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "匈牙利", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "義大利", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "瑞典", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "芬蘭", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "波蘭", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "俄羅斯", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "加拿大", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "美國", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "97", "op_body": "請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "６ 請問進修的學校名稱？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 23, "op_cid": "97", "op_body": "其他,請填全名:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 6, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 6, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "臺灣大學", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "政治大學", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "清華大學", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "陽明交通大學", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "成功大學", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "中央大學", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "中興大學", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "台北大學", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "中正大學", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "中山大學", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "臺灣海洋大學", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "臺灣師範大學", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "高雄師範大學", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "彰化師範大學", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "台北醫學大學", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "長庚大學", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "台北護理健康大學", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "中國醫藥大學", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "中山醫學大學", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "高雄醫學大學", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "台灣科技大學", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "台北科技大學", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "輔仁大學", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.6667, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "97", "op_body": "其他,請填全名:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 3, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "７ 最主要準備何種考試？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "05", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "國內研究所(含學士後)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "出國留學", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "證照", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公務人員(如高普考)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "就業(如國營事業,銀行..招考)", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "97", "op_body": "其他情形,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 7, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 7, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "國內研究所(含學士後)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "出國留學", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "證照", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公務人員(如高普考)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "就業(如國營事業,銀行..招考)", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "97", "op_body": "其他情形,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "８ 準備去那一個國家留學？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "27", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "韓國", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "日本", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新加坡", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "阿拉伯", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "澳洲", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "紐西蘭", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "英國", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "法國", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "荷蘭", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "丹麥", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "比利時", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "西班牙", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "德國", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "捷克", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "瑞士", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "奧地利", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "匈牙利", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "義大利", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "瑞典", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "芬蘭", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "波蘭", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "俄羅斯", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "加拿大", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "美國", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 8, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 8, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "韓國", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "日本", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新加坡", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "阿拉伯", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "澳洲", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "紐西蘭", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "英國", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "法國", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "荷蘭", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "丹麥", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "比利時", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "西班牙", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "德國", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "捷克", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "瑞士", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "奧地利", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "匈牙利", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "義大利", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "瑞典", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "芬蘭", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "波蘭", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "俄羅斯", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "加拿大", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "美國", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 3, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "９ 是否有申請到國內(外) 經費補助？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}, {"range_hi": "98", "range_lo": "98"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "是", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "否", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "98", "op_body": "申請中/還沒申請/不想申請", "op_head": "(98) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 9, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 9, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "是", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "否", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "98", "op_body": "申請中/還沒申請/不想申請", "op_head": "(98) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１０ 到現在還在尋找工作的最大可能原因為何？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "沒有工作機會", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "薪水不滿意", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "公司財務或制度不穩健", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "工作地點不適合", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "與所學不符", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "不符合家人的期望", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作內容不滿意", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "剛離職投履歷待通知", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "剛退伍投履歷待通知", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "剛畢業投履歷待通知", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "97", "op_body": "其他情形,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 10, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 10, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "沒有工作機會", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "薪水不滿意", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "公司財務或制度不穩健", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "工作地點不適合", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "與所學不符", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "不符合家人的期望", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作內容不滿意", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "剛離職投履歷待通知", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "剛退伍投履歷待通知", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "剛畢業投履歷待通知", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "97", "op_body": "其他情形,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１１ 目前已花多久時間找工作？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "06", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "約1個月以內", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "約1個月以上至2個月內", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "約2個月以上至3個月內", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "約3個月以上至4個月內", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "約4個月以上至6個月內", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "約6個月以上", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 11, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 11, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "約1個月以內", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "約1個月以上至2個月內", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "約2個月以上至3個月內", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "約3個月以上至4個月內", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "約4個月以上至6個月內", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "約6個月以上", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１２ 您現在主要的工作所在地點為何？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "09", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "境內(包含台灣本島及離島)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "香港、澳門、大陸地區", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "亞洲其他國家", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "大洋洲(如澳洲、紐西蘭..)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非洲", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "歐洲", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "北美洲(如加拿大、美國、墨西哥.)", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "中美洲(如哥斯大黎加..)", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "南美洲(如阿根廷、巴西、智利..)", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 12, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 12, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "境內(包含台灣本島及離島)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "香港、澳門、大陸地區", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "亞洲其他國家", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "大洋洲(如澳洲、紐西蘭..)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非洲", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "歐洲", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "北美洲(如加拿大、美國、墨西哥.)", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "中美洲(如哥斯大黎加..)", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "南美洲(如阿根廷、巴西、智利..)", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１３ 在台灣的那一個縣市工作？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "22", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "基隆市", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "新北市", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "台北市", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "桃園市", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "新竹縣", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新竹市", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "苗栗縣", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "台中市", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "南投縣", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "彰化縣", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "雲林縣", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "嘉義縣", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "嘉義市", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "台南市", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "高雄市", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "屏東縣", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "台東縣", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "花蓮縣", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "宜蘭縣", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "連江縣", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "金門縣", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "澎湖縣", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.75, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 13, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 13, "is_open_ended": false, "has_image": true, "image": {"location": ""}, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "基隆市", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "新北市", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "台北市", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "桃園市", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "新竹縣", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新竹市", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "苗栗縣", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "台中市", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "南投縣", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "彰化縣", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "雲林縣", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "嘉義縣", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "嘉義市", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "台南市", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "高雄市", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "屏東縣", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "台東縣", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "花蓮縣", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "宜蘭縣", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "連江縣", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "金門縣", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "澎湖縣", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.75, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１４ 在@_____@的那一個國家或地區工作？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "03", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 39, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 14, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 14, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "香港", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "澳門", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "大陸", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "韓國", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "日本", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "新加坡", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "馬來西亞", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "印尼", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "菲律賓", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "越南", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "泰國", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "印度", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "阿拉伯", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "土耳其", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "澳洲", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "紐西蘭", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "南非", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "英國", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "法國", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "荷蘭", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "丹麥", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "比利時", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "西班牙", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "德國", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "捷克", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "瑞士", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "奧地利", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "28", "op_body": "匈牙利", "op_head": "(28) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 28, "op_cid": "29", "op_body": "義大利", "op_head": "(29) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 29, "op_cid": "30", "op_body": "瑞典", "op_head": "(30) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 30, "op_cid": "31", "op_body": "芬蘭", "op_head": "(31) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 31, "op_cid": "32", "op_body": "波蘭", "op_head": "(32) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 32, "op_cid": "33", "op_body": "俄羅斯", "op_head": "(33) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 33, "op_cid": "34", "op_body": "加拿大", "op_head": "(34) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 34, "op_cid": "35", "op_body": "美國", "op_head": "(35) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 35, "op_cid": "36", "op_body": "墨西哥", "op_head": "(36) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 36, "op_cid": "37", "op_body": "巴西", "op_head": "(37) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 37, "op_cid": "38", "op_body": "阿根廷", "op_head": "(38) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 38, "op_cid": "39", "op_body": "智利", "op_head": "(39) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 39, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 3, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１５ 工作服務公司(或單位)屬性：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "07", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "企業(含國營、民營..等)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "政府部門(含職業軍人)", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "學校", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "非營利法人團體(學術研究機構)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非營利法人團體(非學術研究機構)", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創業", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "自由工作者(以接案維生或個人服務)", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 15, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 15, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**若同時有多份Part Time工作，請以主要工作時數較長者作答", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "企業(含國營、民營..等)", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "政府部門(含職業軍人)", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "學校", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "非營利法人團體(學術研究機構)", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非營利法人團體(非學術研究機構)", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創業", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "自由工作者(以接案維生或個人服務)", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１６ 請問目前工作在國內或國外服務的學校名稱？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "01", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "臺灣大學", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 16, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 16, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**請填全名", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "臺灣大學", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１７ 請問您的工作性質有沒有擔任「教職工作」？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "有", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "沒有", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 17, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 17, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "有", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "沒有", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１８ 請問目前工作服務的學術研究機構名稱是？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "07", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "中央研究院", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "工業技術研究院", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "台灣經濟研究院", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "台灣綜合研究院", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "中華經濟研究院", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國家衛生研究院", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "中山科學研究院", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 18, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 18, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "中央研究院", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "工業技術研究院", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "台灣經濟研究院", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "台灣綜合研究院", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "中華經濟研究院", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國家衛生研究院", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "中山科學研究院", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "１９ 您目前服務的部門別(請填最相似的工作服務部門) ？", "name": "", "skip": [], "type": "1", "table": {"rows": [["(01) 教育訓練部門", "包括學校教師等"], ["(02) 行政部門", "包括秘書處、管理部、機要部、教育局(處)、高等教育司、綜合業務處、外交國防法務處等"], ["(03) 業務部門", "包括事業部等"], ["(04) 企劃/行銷部門", "包括行銷部、行銷企劃部、活動部等"], ["(05) 研發/開發部門", "包括軟/硬體研發部、開發部、研發中心、開發部門、行銷部門、研究發展處等"], ["(06) 設計部門", "包括設計工程部、設計研發部等"], ["(07) 人力資源/培訓部門", "包括人力資源部、人事處、培訓部門等"], ["(08) 生產/製造部門", "包括生產管理部、製造部門等"], ["(09) 工程部門", "包括製程部門等"], ["(10) 營業(運)部門", "包括營業企劃部等"], ["(11) 品保部門", "包括品保、品管部門等"], ["(12) 物流部門", "包括船務部、車櫃聯運部等"], ["(13) 市場調查部門", "包括市場研究部等"], ["(14) 公關部門", "包括新聞部門、媒體等"], ["(15) 財務/會計部門", "包括記帳部、會計部、會計處、財務企劃部、財會部、審計部門、財務管理處等"], ["(16) 採購部門", "包括總務部、總務處等"], ["(17) 統計部門", "包括統計處、主計處等"], ["(18) 法務部門", "包括法制處、法務室、政風處等"], ["(19) 資訊部門", "包括行銷資訊部、程式設計部門、資訊安全部門、資安部門、資訊處等"], ["(20) 客服部門", "包括客服中心等"], ["(21) 稽核部門", "包含政風處、稽核室等"], ["(22) 醫療部門", "包括醫療..等"], ["(97) 其他部門(請說明：_______)", "請敘明部門名稱"]], "header": ["部門", "說明"]}, "is_zip": false, "ranges": [{"range_hi": "22", "range_lo": "01"}, {"range_hi": "97", "range_lo": "96"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "教育訓練部門", "op_head": "(01) ", "op_note": "   包括學校教師等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "行政部門", "op_head": "(02) ", "op_note": "   包括秘書處、管理部、機要部、教育局(處) 、高等教育司、綜合業務處、外交國防法務處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "業務部門", "op_head": "(03) ", "op_note": "   包括事業部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "企劃/行銷部門", "op_head": "(04) ", "op_note": "   包括行銷部、行銷企劃部、活動部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "研發/開發部門", "op_head": "(05) ", "op_note": "   包括軟/硬體研發部、開發部、研發中心、開發部門、行銷部門、研究發展處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "設計部門", "op_head": "(06) ", "op_note": "   包括設計工程部、設計研發部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "人力資源/培訓部門", "op_head": "(07) ", "op_note": "   包括人力資源部、人事處、培訓部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生產/製造部門", "op_head": "(08) ", "op_note": "   包括生產管理部、製造部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "工程部門", "op_head": "(09) ", "op_note": "   包括製程部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "營業(運) 部門", "op_head": "(10) ", "op_note": "   包括營業企劃部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "品保部門", "op_head": "(11) ", "op_note": "   包括品保、品管部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "物流部門", "op_head": "(12) ", "op_note": "   包括船務部、車櫃聯運部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "市場調查部門", "op_head": "(13) ", "op_note": "   包括市場研究部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "公關部門", "op_head": "(14) ", "op_note": "   包括新聞部門、媒體等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "財務/會計部門", "op_head": "(15) ", "op_note": "   包括記帳部、會計部、會計處、財務企劃部、財會部、審計部門、財務管理處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "採購部門", "op_head": "(16) ", "op_note": "   包括總務部、總務處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "統計部門", "op_head": "(17) ", "op_note": "   包括統計處、主計處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "法務部門", "op_head": "(18) ", "op_note": "   包括法制處、法務室、政風處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "資訊部門", "op_head": "(19) ", "op_note": "   包括行銷資訊部、程式設計部門、資訊安全部門、資安部門、資訊處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "客服部門", "op_head": "(20) ", "op_note": "   包括客服中心等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "稽核部門", "op_head": "(21) ", "op_note": "   包含政風處、稽核室等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "醫療部門", "op_head": "(22) ", "op_note": "   包括醫療..等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "97", "op_body": "其他部門,請說明:_________", "op_head": "(97) ", "op_note": "   請敘明部門名稱", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 19, "is_narrative": false, "len_each_ans": 2, "render_table": true, "user_qst_cid": 19, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明部門名稱：", "txt_max_len": 50, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "部門   說明", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "教育訓練部門", "op_head": "(01) ", "op_note": "   包括學校教師等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "行政部門", "op_head": "(02) ", "op_note": "   包括秘書處、管理部、機要部、教育局(處) 、高等教育司、綜合業務處、外交國防法務處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "業務部門", "op_head": "(03) ", "op_note": "   包括事業部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "企劃/行銷部門", "op_head": "(04) ", "op_note": "   包括行銷部、行銷企劃部、活動部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "研發/開發部門", "op_head": "(05) ", "op_note": "   包括軟/硬體研發部、開發部、研發中心、開發部門、行銷部門、研究發展處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "設計部門", "op_head": "(06) ", "op_note": "   包括設計工程部、設計研發部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "人力資源/培訓部門", "op_head": "(07) ", "op_note": "   包括人力資源部、人事處、培訓部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生產/製造部門", "op_head": "(08) ", "op_note": "   包括生產管理部、製造部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "工程部門", "op_head": "(09) ", "op_note": "   包括製程部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "營業(運) 部門", "op_head": "(10) ", "op_note": "   包括營業企劃部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "品保部門", "op_head": "(11) ", "op_note": "   包括品保、品管部門等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "物流部門", "op_head": "(12) ", "op_note": "   包括船務部、車櫃聯運部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "市場調查部門", "op_head": "(13) ", "op_note": "   包括市場研究部等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "公關部門", "op_head": "(14) ", "op_note": "   包括新聞部門、媒體等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "財務/會計部門", "op_head": "(15) ", "op_note": "   包括記帳部、會計部、會計處、財務企劃部、財會部、審計部門、財務管理處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "採購部門", "op_head": "(16) ", "op_note": "   包括總務部、總務處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "統計部門", "op_head": "(17) ", "op_note": "   包括統計處、主計處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "法務部門", "op_head": "(18) ", "op_note": "   包括法制處、法務室、政風處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "資訊部門", "op_head": "(19) ", "op_note": "   包括行銷資訊部、程式設計部門、資訊安全部門、資安部門、資訊處等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "客服部門", "op_head": "(20) ", "op_note": "   包括客服中心等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "稽核部門", "op_head": "(21) ", "op_note": "   包含政風處、稽核室等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "醫療部門", "op_head": "(22) ", "op_note": "   包括醫療..等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "97", "op_body": "其他部門,請說明:_________", "op_head": "(97) ", "op_note": "   請敘明部門名稱", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２０ 目前任職公司的規模為何？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "07", "range_lo": "01"}, {"range_hi": "98", "range_lo": "98"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "1～9人", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "10～49人", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "50～99人", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "100～199人", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "200～499人", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "500～999人", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "1000人及以上", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "98", "op_body": "不知道", "op_head": "(98) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 20, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 20, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**即工作地方的公司員工人數", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "1～9人", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "10～49人", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "50～99人", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "100～199人", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "200～499人", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "500～999人", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "1000人及以上", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "98", "op_body": "不知道", "op_head": "(98) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２１ 您目前是否擔任主管?", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "是", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "否", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 21, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 21, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "是", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "否", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２２ 請問管理人數為：", "name": "", "skip": [], "type": "3", "table": {}, "is_zip": false, "ranges": [{"range_hi": "9998", "range_lo": "0000"}], "is_date": false, "is_time": false, "options": [], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 22, "is_narrative": false, "len_each_ans": 4, "render_table": false, "user_qst_cid": 22, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "請輸入人數(0 ~ 9998) _ _ _ _ 人", "original_options": [], "num_opts_each_line": -1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２３ 您目前最主要的工作行業類別為？", "name": "", "skip": [], "type": "1", "table": {"rows": [["(01) 農、林、漁、牧業", "從事農作物栽培、畜牧、農事及畜牧服務、造林、伐木及採集、漁撈及水產養殖等之行業等"], ["(02) 礦業及土石採取業", "石油及天然氣、砂、石及黏土、其他礦業及土石採取業等"], ["(03) 製造業", "半導體、影像顯示、生技醫藥、智慧手持裝置與通訊設備、食品製造、紡織、紙業及印刷業、石油、化學材料及製品業、非金屬製品業、金屬工業、機械設備業、電子零組件、電力設備製造業、汽車及其零件製造業、其他運輸工具製造業、產業用機械設備維修及安裝業、其他製造業等"], ["(04) 電力及燃氣供應業", "從事電力、氣體燃料及蒸汽供應之行業等"], ["(05) 用水供應及污染整治業", "用水供應業、廢（污）水處理、廢棄物清除、處理及資源回收業等"], ["(06) 營建工程業", "建築工程、土木工程、專門營造等"], ["(07) 批發及零售業", "從事有形商品之批發、零售、經紀及代理之行業；銷售商品所附帶不改變商品本質之簡單處理，如包裝、清洗、分級、摻混、運送、安裝、修理等亦歸入本類。"], ["(08) 運輸及倉儲業", "海陸空運輸、郵政及快遞、倉儲等"], ["(09) 住宿及餐飲業", "從事短期或臨時性住宿服務及餐飲服務之行業等"], ["(10) 出版、影音製作、傳播及資通訊服務業", "包含數位遊戲、電腦動畫、行動應用服務、數位影音、數位學習、數位出版典藏、出版、影片服務、聲音錄製及音樂出版、傳播及節目播送、電信服務、電腦系統設計服務、資料處理及資訊供應服務"], ["(11) 金融及保險業", "金融仲介、保險、證券期貨及其他金融業等"], ["(12) 不動產業", "不動產開發、都市更新、不動產經營及相關服務等"], ["(13) 專業、科學及技術服務業", "法律、會計、企業總管理機構及管理顧問、建築、工程服務及技術檢測、分析服務、能源技術服務、研究發展、廣告及市場研究、專門設計、獸醫、攝影、翻譯、藝人及模特兒等"], ["(14) 支援服務業", "租賃業、就業服務業、旅行業、保全及私家偵探、建築物及綠化服務、會議展覽服務、業務及辦公室支援服務等"], ["(15) 公共行政及國防、強制性社會安全", "公共行政業、國防事務、強制性社會安全、國際組織及外國機構等"], ["(16) 教育業", "學前、小學、中學、大專校院、特殊教育、外語教育、藝術教育、運動及休閒教育商業、資訊及專業管理教育等"], ["(17) 醫療保健及社會工作服務業", "醫療保健服務、居住照顧服務、其他社會工作服務等"], ["(18) 藝術、娛樂及休閒服務業", "創作及藝術表演、圖書館、檔案保存、博物館及類似機構、博弈業、運動、娛樂及休閒服務等"], ["(19) 其他服務業", "工商業團體、宗教、職業及類似組織、個人及家庭用品維修、洗衣、理容、殯葬、家事等"]], "header": ["主計處行業類別", "說明"]}, "is_zip": false, "ranges": [{"range_hi": "19", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "農、林、漁、牧業", "op_head": "(01) ", "op_note": "   從事農作物栽培、畜牧、農事及畜牧服務、造林、伐木及採集、漁撈及水產養殖等之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "礦業及土石採取業", "op_head": "(02) ", "op_note": "   石油及天然氣、砂、石及黏土、其他礦業及土石採取業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "製造業", "op_head": "(03) ", "op_note": "   半導體、影像顯示、生技醫藥、智慧手持裝置與通訊設備、食品製造、紡織、紙業及印刷業、石油、化學材料及製品業、非金屬製品業、金屬工業、機械設備業、電子零組件、電力設備製造業、汽車及其零件製造業、其他運輸工具製造業、產業用機械設備維修及安裝業、其他製造業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "電力及燃氣供應業", "op_head": "(04) ", "op_note": "   從事電力、氣體燃料及蒸汽供應之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "用水供應及污染整治業", "op_head": "(05) ", "op_note": "   用水供應業、廢（污）水處理、廢棄物清除、處理及資源回收業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "營建工程業", "op_head": "(06) ", "op_note": "   建築工程、土木工程、專門營造等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "批發及零售業", "op_head": "(07) ", "op_note": "   從事有形商品之批發、零售、經紀及代理之行業；銷售商品所附帶不改變商品本質之簡單處理，如包裝、清洗、分級、摻混、運送、安裝、修理等亦歸入本類。", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "運輸及倉儲業", "op_head": "(08) ", "op_note": "   海陸空運輸、郵政及快遞、倉儲等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "住宿及餐飲業", "op_head": "(09) ", "op_note": "   從事短期或臨時性住宿服務及餐飲服務之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "出版、影音製作、傳播及資通訊服務業", "op_head": "(10) ", "op_note": "   包含數位遊戲、電腦動畫、行動應用服務、數位影音、數位學習、數位出版典藏、出版、影片服務、聲音錄製及音樂出版、傳播及節目播送、電信服務、電腦系統設計服務、資料處理及資訊供應服務", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "金融及保險業", "op_head": "(11) ", "op_note": "   金融仲介、保險、證券期貨及其他金融業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "不動產業", "op_head": "(12) ", "op_note": "   不動產開發、都市更新、不動產經營及相關服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "專業、科學及技術服務業", "op_head": "(13) ", "op_note": "   法律、會計、企業總管理機構及管理顧問、建築、工程服務及技術檢測、分析服務、能源技術服務、研究發展、廣告及市場研究、專門設計、獸醫、攝影、翻譯、藝人及模特兒等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "支援服務業", "op_head": "(14) ", "op_note": "   租賃業、就業服務業、旅行業、保全及私家偵探、建築物及綠化服務、會議展覽服務、業務及辦公室支援服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "公共行政及國防、強制性社會安全", "op_head": "(15) ", "op_note": "   公共行政業、國防事務、強制性社會安全、國際組織及外國機構等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "教育業", "op_head": "(16) ", "op_note": "   學前、小學、中學、大專校院、特殊教育、外語教育、藝術教育、運動及休閒教育商業、資訊及專業管理教育等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "醫療保健及社會工作服務業", "op_head": "(17) ", "op_note": "   醫療保健服務、居住照顧服務、其他社會工作服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "藝術、娛樂及休閒服務業", "op_head": "(18) ", "op_note": "   創作及藝術表演、圖書館、檔案保存、博物館及類似機構、博弈業、運動、娛樂及休閒服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "其他服務業", "op_head": "(19) ", "op_note": "   工商業團體、宗教、職業及類似組織、個人及家庭用品維修、洗衣、理容、殯葬、家事等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 23, "is_narrative": false, "len_each_ans": 2, "render_table": true, "user_qst_cid": 23, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**如計程車司機請勾「運輸及倉儲業」，但在醫院開救護車者，請勾選「醫療保護及社會工作服務業」…等主計處行業類別   說明", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "農、林、漁、牧業", "op_head": "(01) ", "op_note": "   從事農作物栽培、畜牧、農事及畜牧服務、造林、伐木及採集、漁撈及水產養殖等之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "礦業及土石採取業", "op_head": "(02) ", "op_note": "   石油及天然氣、砂、石及黏土、其他礦業及土石採取業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "製造業", "op_head": "(03) ", "op_note": "   半導體、影像顯示、生技醫藥、智慧手持裝置與通訊設備、食品製造、紡織、紙業及印刷業、石油、化學材料及製品業、非金屬製品業、金屬工業、機械設備業、電子零組件、電力設備製造業、汽車及其零件製造業、其他運輸工具製造業、產業用機械設備維修及安裝業、其他製造業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "電力及燃氣供應業", "op_head": "(04) ", "op_note": "   從事電力、氣體燃料及蒸汽供應之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "用水供應及污染整治業", "op_head": "(05) ", "op_note": "   用水供應業、廢（污）水處理、廢棄物清除、處理及資源回收業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "營建工程業", "op_head": "(06) ", "op_note": "   建築工程、土木工程、專門營造等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "批發及零售業", "op_head": "(07) ", "op_note": "   從事有形商品之批發、零售、經紀及代理之行業；銷售商品所附帶不改變商品本質之簡單處理，如包裝、清洗、分級、摻混、運送、安裝、修理等亦歸入本類。", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "運輸及倉儲業", "op_head": "(08) ", "op_note": "   海陸空運輸、郵政及快遞、倉儲等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "住宿及餐飲業", "op_head": "(09) ", "op_note": "   從事短期或臨時性住宿服務及餐飲服務之行業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "出版、影音製作、傳播及資通訊服務業", "op_head": "(10) ", "op_note": "   包含數位遊戲、電腦動畫、行動應用服務、數位影音、數位學習、數位出版典藏、出版、影片服務、聲音錄製及音樂出版、傳播及節目播送、電信服務、電腦系統設計服務、資料處理及資訊供應服務", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "金融及保險業", "op_head": "(11) ", "op_note": "   金融仲介、保險、證券期貨及其他金融業等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "不動產業", "op_head": "(12) ", "op_note": "   不動產開發、都市更新、不動產經營及相關服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "專業、科學及技術服務業", "op_head": "(13) ", "op_note": "   法律、會計、企業總管理機構及管理顧問、建築、工程服務及技術檢測、分析服務、能源技術服務、研究發展、廣告及市場研究、專門設計、獸醫、攝影、翻譯、藝人及模特兒等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "支援服務業", "op_head": "(14) ", "op_note": "   租賃業、就業服務業、旅行業、保全及私家偵探、建築物及綠化服務、會議展覽服務、業務及辦公室支援服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "公共行政及國防、強制性社會安全", "op_head": "(15) ", "op_note": "   公共行政業、國防事務、強制性社會安全、國際組織及外國機構等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "教育業", "op_head": "(16) ", "op_note": "   學前、小學、中學、大專校院、特殊教育、外語教育、藝術教育、運動及休閒教育商業、資訊及專業管理教育等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "醫療保健及社會工作服務業", "op_head": "(17) ", "op_note": "   醫療保健服務、居住照顧服務、其他社會工作服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "藝術、娛樂及休閒服務業", "op_head": "(18) ", "op_note": "   創作及藝術表演、圖書館、檔案保存、博物館及類似機構、博弈業、運動、娛樂及休閒服務等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "其他服務業", "op_head": "(19) ", "op_note": "   工商業團體、宗教、職業及類似組織、個人及家庭用品維修、洗衣、理容、殯葬、家事等", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２４ 您目前平均一個月的工作收入大約多少？(以新台幣計)", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "29", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "22,000元以下", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "22,001～25,000元", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "25,001～28,000元", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "28,001～31,000元", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "31,001～34,000元", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "34,001～37,000元", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "37,001～40,000元", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "40,001～43,000元", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "43,001～46,000元", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "46,001～49,000元", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "49,001～52,000元", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "52,001～55,000元", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "55,001～60,000元", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "60,001～65,000元", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "65,001～70,000元", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "70,001～75,000元", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "75,001～80,000元", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "80,001～85,000元", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "85,001～90,000元", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "90,001～95,000元", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "95,001～100,000元", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "100,001～110,000元", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "110,001～120,000元", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "120,001～130,000元", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "130,001～140,000元", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "140,001～150,000元", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "150,001～170,000元", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "28", "op_body": "170,001～190,000元", "op_head": "(28) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 28, "op_cid": "29", "op_body": "190,001～210,000元", "op_head": "(29) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 29, "op_cid": "30", "op_body": "210,001元及以上", "op_head": "(30) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 24, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 24, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**指含固定津貼、交通費、膳食費、水電費、按月發放之工作(生產、績效、業績)獎金及全勤獎金等", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "22,000元以下", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "22,001～25,000元", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "25,001～28,000元", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "28,001～31,000元", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "31,001～34,000元", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "34,001～37,000元", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "37,001～40,000元", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "40,001～43,000元", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "43,001～46,000元", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "46,001～49,000元", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "49,001～52,000元", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "52,001～55,000元", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "55,001～60,000元", "op_head": "(13) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "60,001～65,000元", "op_head": "(14) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "65,001～70,000元", "op_head": "(15) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "70,001～75,000元", "op_head": "(16) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "75,001～80,000元", "op_head": "(17) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "80,001～85,000元", "op_head": "(18) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "85,001～90,000元", "op_head": "(19) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "90,001～95,000元", "op_head": "(20) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "95,001～100,000元", "op_head": "(21) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "100,001～110,000元", "op_head": "(22) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "110,001～120,000元", "op_head": "(23) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "120,001～130,000元", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 24, "op_cid": "25", "op_body": "130,001～140,000元", "op_head": "(25) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 25, "op_cid": "26", "op_body": "140,001～150,000元", "op_head": "(26) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 26, "op_cid": "27", "op_body": "150,001～170,000元", "op_head": "(27) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 27, "op_cid": "28", "op_body": "170,001～190,000元", "op_head": "(28) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 28, "op_cid": "29", "op_body": "190,001～210,000元", "op_head": "(29) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 29, "op_cid": "30", "op_body": "210,001元及以上", "op_head": "(30) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 3, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２５ 您原先就讀系、所、或學位學程的專業訓練課程，對於您目前工作的幫助程度為何？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "05", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "非常有幫助", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "有幫助", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "普通", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "沒幫助", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非常沒幫助", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 25, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 25, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "非常有幫助", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "有幫助", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "普通", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "沒幫助", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "非常沒幫助", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２６ 您在學期間以下哪些「學習經驗」對於現在工作最有幫助？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "09", "range_lo": "01"}, {"range_hi": "97", "range_lo": "96"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "專業知識、知能傳授", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "建立同學及老師人脈", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "校內實務課程", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "校外業界實習", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "社團活動", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "語言學習", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "參與國際交流活動", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "志工服務、服務學習", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "擔任研究或教學助理", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "96", "op_body": "都沒有", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "97", "op_body": "其他訓練,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.6667, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 3, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 26, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 26, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": ["96"], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**複選最多3項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "專業知識、知能傳授", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "建立同學及老師人脈", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "校內實務課程", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "校外業界實習", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "社團活動", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "語言學習", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "參與國際交流活動", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "志工服務、服務學習", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "擔任研究或教學助理", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "96", "op_body": "都沒有", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 0.3333, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "97", "op_body": "其他訓練,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.6667, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 3, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２７ 依您的經驗，您認為「溝通表達能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 27, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 27, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２８ 依您的經驗，您認為「持續學習能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 28, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 28, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "２９ 依您的經驗，您認為「人際互動能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 29, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 29, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３０ 依您的經驗，您認為「團隊合作能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 30, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 30, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３１ 依您的經驗，您認為「問題解決能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 31, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 31, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３２ 依您的經驗，您認為「創新能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 32, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 32, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３３ 依您的經驗，您認為「工作紀律、責任感及時間管理能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 33, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 33, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３４ 依您的經驗，您認為「資訊科技應用能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 34, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 34, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３５ 依您的經驗，您認為「外語能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 35, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 35, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３６ 依您的經驗，您認為「跨領域整合能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 36, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 36, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３７ 依您的經驗，您認為「領導能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 37, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 37, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３８ 依您的經驗，您認為「情緒管理能力」在職場能力的重要程度是：", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "10", "range_lo": "00"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 38, "qst_group": 1, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 38, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**重要程度以0至10分標示；0為最不重要、10為最重要", "original_options": [{"op_id": 0, "op_cid": "00", "op_body": "0分", "op_head": "(00) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "01", "op_body": "1分", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "02", "op_body": "2分", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "03", "op_body": "3分", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "04", "op_body": "4分", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "05", "op_body": "5分", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "06", "op_body": "6分", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "07", "op_body": "7分", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "08", "op_body": "8分", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "09", "op_body": "9分", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.25, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "10", "op_body": "10分", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 4, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "３９ 根據您畢業到現在的經驗，學校最應該幫學弟妹加強以下哪些能力？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "12", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "溝通表達能力", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "持續學習能力", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人際互動能力", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "團隊合作能力", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "問題解決能力", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創新能力", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作紀律、責任感及時間管理能力", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "資訊科技應用能力", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "外語能力", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "跨領域整合能力", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "領導能力", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "情緒管理能力", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 3, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 39, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 39, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**複選最多3項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "溝通表達能力", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "持續學習能力", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人際互動能力", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "團隊合作能力", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "問題解決能力", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創新能力", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作紀律、責任感及時間管理能力", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "資訊科技應用能力", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "外語能力", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "跨領域整合能力", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "領導能力", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "情緒管理能力", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４０ 根據您畢業後到現在的經驗，您認為學校對您那些能力的培養最有幫助？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "12", "range_lo": "01"}, {"range_hi": "97", "range_lo": "97"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "溝通表達能力", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "持續學習能力", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人際互動能力", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "團隊合作能力", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "問題解決能力", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創新能力", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作紀律、責任感及時間管理能力", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "資訊科技應用能力", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "外語能力", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "跨領域整合能力", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "領導能力", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "情緒管理能力", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 3, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 40, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 40, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**複選最多3項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "溝通表達能力", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "持續學習能力", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人際互動能力", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "團隊合作能力", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "問題解決能力", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "創新能力", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "工作紀律、責任感及時間管理能力", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "資訊科技應用能力", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "外語能力", "op_head": "(09) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "跨領域整合能力", "op_head": "(10) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "領導能力", "op_head": "(11) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "情緒管理能力", "op_head": "(12) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４１ 如果您現在有進修機會的話，「最」想在學校進修的是哪一個學門?", "name": "", "skip": [], "type": "1", "table": {"rows": [["(01) 教育學門", "綜合教育學、普通科目教育學、專業科目教育學、學前教育學、成人教育學、特殊教育學、教育行政學、教育科技學、教育測驗評量學、其他教育學"], ["(02) 藝術學門", "美術學、雕塑藝術學、美術工藝學、音樂學、戲劇舞蹈學、視覺藝術學、綜合藝術學、民俗藝術學類、應用藝術學、藝術行政學"], ["(03) 人文學門", "臺灣語文學、中國語文學、外國語文學、其他語文學、、翻譯學、比較文學學、語言學、宗教學、歷史學、人類學學、哲學學、文獻學學、其他人文學"], ["(04) 設計學門", "綜合設計學、視覺傳達設計學、產品設計學、空間設計學、其他設計學"], ["(05) 社會及行為科學學門", "經濟學、政治學、社會學、民族學、心理學、地理學、區域研究學、公共行政學、國際事務學、綜合社會及行為科學學"], ["(06) 傳播學門", "一般大眾傳播學、新聞學、廣播電視學、公共關係學、博物館學、圖書資訊檔案學、圖文傳播學、廣告學、其他傳播及資訊學"], ["(07) 商業及管理學門", "一般商業學、會計學、企業管理學、貿易學、財務金融學、風險管理學、財政學、行銷與流通學、醫管學、其他商業及管理學"], ["(08) 法律學門", "一般法律學、專業法律學、其他法律學"], ["(09) 生命科學學門", "生物學、生態學、生物科技學、微生物學、生物化學學、生物訊息學、其他生命科學"], ["(10) 自然科學學門", "化學學、地球科學學、物理學、大氣科學學、海洋科學學、天文及太空科學學、其他自然科學學"], ["(11) 數學及統計學門", "數學學、統計學、其他數學及統計學"], ["(12) 電算機學門", "電算機一般學、網路學、軟體發展學、系統設計學、電算機應用學、其他電算機學"], ["(13) 工程學門", "電資工程學、機械工程學、土木工程學、化學工程學、材料工程學、工業工程學、紡織工程學類、測量工程學、環境工程學、河海工程學、生醫工程學、核子工程學、綜合工程學、其他工程學"], ["(14) 建築及都市規劃學門", "建築學、景觀設計學、都巿規劃學、其他建築及都巿規劃學"], ["(15) 農業科學學門", "一般農業學、畜牧學、園藝學、植物保護學、農業經濟及推廣學、食品科學、水土保持學、農業化學類、農業技術學類、林業學類、漁業學類、其他農林漁牧學類"], ["(16) 獸醫學門", "獸醫學類"], ["(17) 醫藥衛生學門", "醫學學類、公共衛生學類、藥學學類、復健醫學學類、營養學類、護理學類、醫學技術及檢驗學類、牙醫學類、其他醫藥衛生學類"], ["(18) 社會服務學門", "身心障礙服務學類、老年服務學類、社會工作學類、兒童保育學類、其他社會服務學類"], ["(19) 民生學門", "餐旅服務學類、觀光休閒學類、競技運動學類、運動科技學類、運動休閒及休閒管理學類、生活應用科學學類、服飾學類、美容學類、其他民生學類"], ["(20) 運輸服務學門", "運輸管理學類、航空學類、航海學類、其他運輸服務學類"], ["(21) 環境保護學門", "環境資源學類、環境防災學類、其他環境保護學類"], ["(22) 軍警國防安全學門", "警政學類、軍事學類、其他軍警國防安全學類"], ["(23) 其他學門", "其他不能歸類之各學類"], ["(24) 沒有進修需求", ""]], "header": ["學門名稱", "說明"]}, "is_zip": false, "ranges": [{"range_hi": "24", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "教育學門", "op_head": "(01) ", "op_note": "   綜合教育學、普通科目教育學、專業科目教育學、學前教育學、成人教育學、特殊教育學、教育行政學、教育科技學、教育測驗評量學、其他教育學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "藝術學門", "op_head": "(02) ", "op_note": "   美術學、雕塑藝術學、美術工藝學、音樂學、戲劇舞蹈學、視覺藝術學、綜合藝術學、民俗藝術學類、應用藝術學、藝術行政學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人文學門", "op_head": "(03) ", "op_note": "   臺灣語文學、中國語文學、外國語文學、其他語文學、、翻譯學、比較文學學、語言學、宗教學、歷史學、人類學學、哲學學、文獻學學、其他人文學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "設計學門", "op_head": "(04) ", "op_note": "   綜合設計學、視覺傳達設計學、產品設計學、空間設計學、其他設計學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "社會及行為科學學門", "op_head": "(05) ", "op_note": "   經濟學、政治學、社會學、民族學、心理學、地理學、區域研究學、公共行政學、國際事務學、綜合社會及行為科學學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "傳播學門", "op_head": "(06) ", "op_note": "   一般大眾傳播學、新聞學、廣播電視學、公共關係學、博物館學、圖書資訊檔案學、圖文傳播學、廣告學、其他傳播及資訊學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "商業及管理學門", "op_head": "(07) ", "op_note": "   一般商業學、會計學、企業管理學、貿易學、財務金融學、風險管理學、財政學、行銷與流通學、醫管學、其他商業及管理學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "法律學門", "op_head": "(08) ", "op_note": "   一般法律學、專業法律學、其他法律學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "生命科學學門", "op_head": "(09) ", "op_note": "   生物學、生態學、生物科技學、微生物學、生物化學學、生物訊息學、其他生命科學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "自然科學學門", "op_head": "(10) ", "op_note": "   化學學、地球科學學、物理學、大氣科學學、海洋科學學、天文及太空科學學、其他自然科學學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "數學及統計學門", "op_head": "(11) ", "op_note": "   數學學、統計學、其他數學及統計學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "電算機學門", "op_head": "(12) ", "op_note": "   電算機一般學、網路學、軟體發展學、系統設計學、電算機應用學、其他電算機學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "工程學門", "op_head": "(13) ", "op_note": "   電資工程學、機械工程學、土木工程學、化學工程學、材料工程學、工業工程學、紡織工程學類、測量工程學、環境工程學、河海工程學、生醫工程學、核子工程學、綜合工程學、其他工程學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "建築及都市規劃學門", "op_head": "(14) ", "op_note": "   建築學、景觀設計學、都巿規劃學、其他建築及都巿規劃學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "農業科學學門", "op_head": "(15) ", "op_note": "   一般農業學、畜牧學、園藝學、植物保護學、農業經濟及推廣學、食品科學、水土保持學、農業化學類、農業技術學類、林業學類、漁業學類、其他農林漁牧學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "獸醫學門", "op_head": "(16) ", "op_note": "   獸醫學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "醫藥衛生學門", "op_head": "(17) ", "op_note": "   醫學學類、公共衛生學類、藥學學類、復健醫學學類、營養學類、護理學類、醫學技術及檢驗學類、牙醫學類、其他醫藥衛生學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "社會服務學門", "op_head": "(18) ", "op_note": "   身心障礙服務學類、老年服務學類、社會工作學類、兒童保育學類、其他社會服務學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "民生學門", "op_head": "(19) ", "op_note": "   餐旅服務學類、觀光休閒學類、競技運動學類、運動科技學類、運動休閒及休閒管理學類、生活應用科學學類、服飾學類、美容學類、其他民生學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "運輸服務學門", "op_head": "(20) ", "op_note": "   運輸管理學類、航空學類、航海學類、其他運輸服務學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "環境保護學門", "op_head": "(21) ", "op_note": "   環境資源學類、環境防災學類、其他環境保護學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "軍警國防安全學門", "op_head": "(22) ", "op_note": "   警政學類、軍事學類、其他軍警國防安全學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "其他學門", "op_head": "(23) ", "op_note": "   其他不能歸類之各學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "沒有進修需求", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 41, "is_narrative": false, "len_each_ans": 2, "render_table": true, "user_qst_cid": 41, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "學門名稱   說明", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "教育學門", "op_head": "(01) ", "op_note": "   綜合教育學、普通科目教育學、專業科目教育學、學前教育學、成人教育學、特殊教育學、教育行政學、教育科技學、教育測驗評量學、其他教育學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "藝術學門", "op_head": "(02) ", "op_note": "   美術學、雕塑藝術學、美術工藝學、音樂學、戲劇舞蹈學、視覺藝術學、綜合藝術學、民俗藝術學類、應用藝術學、藝術行政學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "人文學門", "op_head": "(03) ", "op_note": "   臺灣語文學、中國語文學、外國語文學、其他語文學、、翻譯學、比較文學學、語言學、宗教學、歷史學、人類學學、哲學學、文獻學學、其他人文學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "設計學門", "op_head": "(04) ", "op_note": "   綜合設計學、視覺傳達設計學、產品設計學、空間設計學、其他設計學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "社會及行為科學學門", "op_head": "(05) ", "op_note": "   經濟學、政治學、社會學、民族學、心理學、地理學、區域研究學、公共行政學、國際事務學、綜合社會及行為科學學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "傳播學門", "op_head": "(06) ", "op_note": "   一般大眾傳播學、新聞學、廣播電視學、公共關係學、博物館學、圖書資訊檔案學、圖文傳播學、廣告學、其他傳播及資訊學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "商業及管理學門", "op_head": "(07) ", "op_note": "   一般商業學、會計學、企業管理學、貿易學、財務金融學、風險管理學、財政學、行銷與流通學、醫管學、其他商業及管理學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "法律學門", "op_head": "(08) ", "op_note": "   一般法律學、專業法律學、其他法律學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "09", "op_body": "生命科學學門", "op_head": "(09) ", "op_note": "   生物學、生態學、生物科技學、微生物學、生物化學學、生物訊息學、其他生命科學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "10", "op_body": "自然科學學門", "op_head": "(10) ", "op_note": "   化學學、地球科學學、物理學、大氣科學學、海洋科學學、天文及太空科學學、其他自然科學學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 10, "op_cid": "11", "op_body": "數學及統計學門", "op_head": "(11) ", "op_note": "   數學學、統計學、其他數學及統計學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 11, "op_cid": "12", "op_body": "電算機學門", "op_head": "(12) ", "op_note": "   電算機一般學、網路學、軟體發展學、系統設計學、電算機應用學、其他電算機學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 12, "op_cid": "13", "op_body": "工程學門", "op_head": "(13) ", "op_note": "   電資工程學、機械工程學、土木工程學、化學工程學、材料工程學、工業工程學、紡織工程學類、測量工程學、環境工程學、河海工程學、生醫工程學、核子工程學、綜合工程學、其他工程學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 13, "op_cid": "14", "op_body": "建築及都市規劃學門", "op_head": "(14) ", "op_note": "   建築學、景觀設計學、都巿規劃學、其他建築及都巿規劃學", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 14, "op_cid": "15", "op_body": "農業科學學門", "op_head": "(15) ", "op_note": "   一般農業學、畜牧學、園藝學、植物保護學、農業經濟及推廣學、食品科學、水土保持學、農業化學類、農業技術學類、林業學類、漁業學類、其他農林漁牧學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 15, "op_cid": "16", "op_body": "獸醫學門", "op_head": "(16) ", "op_note": "   獸醫學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 16, "op_cid": "17", "op_body": "醫藥衛生學門", "op_head": "(17) ", "op_note": "   醫學學類、公共衛生學類、藥學學類、復健醫學學類、營養學類、護理學類、醫學技術及檢驗學類、牙醫學類、其他醫藥衛生學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 17, "op_cid": "18", "op_body": "社會服務學門", "op_head": "(18) ", "op_note": "   身心障礙服務學類、老年服務學類、社會工作學類、兒童保育學類、其他社會服務學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 18, "op_cid": "19", "op_body": "民生學門", "op_head": "(19) ", "op_note": "   餐旅服務學類、觀光休閒學類、競技運動學類、運動科技學類、運動休閒及休閒管理學類、生活應用科學學類、服飾學類、美容學類、其他民生學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 19, "op_cid": "20", "op_body": "運輸服務學門", "op_head": "(20) ", "op_note": "   運輸管理學類、航空學類、航海學類、其他運輸服務學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 20, "op_cid": "21", "op_body": "環境保護學門", "op_head": "(21) ", "op_note": "   環境資源學類、環境防災學類、其他環境保護學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 21, "op_cid": "22", "op_body": "軍警國防安全學門", "op_head": "(22) ", "op_note": "   警政學類、軍事學類、其他軍警國防安全學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 22, "op_cid": "23", "op_body": "其他學門", "op_head": "(23) ", "op_note": "   其他不能歸類之各學類", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 23, "op_cid": "24", "op_body": "沒有進修需求", "op_head": "(24) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４２ 請問您願不願意將教育部與勞動部經過系統勾稽比對後的投保資料結果回饋給母校，以做為學校校務分析？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "願意", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "不願意", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 42, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 42, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "願意", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "不願意", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４３ 請問您107學年度畢業5年的畢業學制是學士、碩士或博士？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "03", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "學士", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "碩士", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "博士", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 43, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 43, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "學士", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "碩士", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "博士", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４４ 根據您的經驗，下列哪些共同必修課程與通識課程所培養的素養，對於求學或工作很有幫助？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "08", "range_lo": "01"}, {"range_hi": "96", "range_lo": "96"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "語文能力與溝通表達", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "獨立思考與創新", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "道德思辨與實踐", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公民意識與社會分析", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "人文關懷與美學素養", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國際視野與多元文化", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "物質文明與科學知識", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生命科學與生物科技", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "96", "op_body": "都沒有幫助/無意見", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 8, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 44, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 44, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": ["96"], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "**複選最多8項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "語文能力與溝通表達", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "獨立思考與創新", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "道德思辨與實踐", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公民意識與社會分析", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "人文關懷與美學素養", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國際視野與多元文化", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "物質文明與科學知識", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生命科學與生物科技", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "96", "op_body": "都沒有幫助/無意見", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "４５ 承上題，您認為學校針對前述八項素養應加強哪些素養，或應該另外再新增何種素養，對於求學或工作更有幫助？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "08", "range_lo": "01"}, {"range_hi": "97", "range_lo": "96"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "語文能力與溝通表達", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "獨立思考與創新", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "道德思辨與實踐", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公民意識與社會分析", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "人文關懷與美學素養", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國際視野與多元文化", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "物質文明與科學知識", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生命科學與生物科技", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "96", "op_body": "都很好不需加強或增加/無意見", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 9, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 45, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 45, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": ["96"], "pre_qst_prompt": "", "additional_text": [{"txt_prompt": "請說明：", "txt_max_len": 100, "txt_min_len": 1, "txt_parent_ans": "97"}], "post_qst_prompt": "**複選最多9項", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "語文能力與溝通表達", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "獨立思考與創新", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 2, "op_cid": "03", "op_body": "道德思辨與實踐", "op_head": "(03) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 3, "op_cid": "04", "op_body": "公民意識與社會分析", "op_head": "(04) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 4, "op_cid": "05", "op_body": "人文關懷與美學素養", "op_head": "(05) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 5, "op_cid": "06", "op_body": "國際視野與多元文化", "op_head": "(06) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 6, "op_cid": "07", "op_body": "物質文明與科學知識", "op_head": "(07) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 7, "op_cid": "08", "op_body": "生命科學與生物科技", "op_head": "(08) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 8, "op_cid": "96", "op_body": "都很好不需加強或增加/無意見", "op_head": "(96) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}, {"op_id": 9, "op_cid": "97", "op_body": "其他,請說明:_________", "op_head": "(97) ", "op_note": "", "op_group": 1, "op_width": 0.5, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 2, "post_options_prompt": "", "allow_repeated_anses": false}, {"qst": "　本問卷已填答完畢，非常感謝您的配合。請問您要不要檢查一下每題的答案？", "name": "", "skip": [], "type": "1", "table": {}, "is_zip": false, "ranges": [{"range_hi": "02", "range_lo": "01"}], "is_date": false, "is_time": false, "options": [{"op_id": 0, "op_cid": "01", "op_body": "要檢查", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "不用檢查", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "pasting": [], "rnd_ops": [], "max_anses": 1, "min_anses": 1, "opt_quotas": [], "is_datetime": false, "sys_qst_cid": 46, "is_narrative": false, "len_each_ans": 2, "render_table": false, "user_qst_cid": 46, "is_open_ended": false, "has_image": false, "num_op_groups": 1, "scale_measure": "nominal", "send_each_ans": false, "mut_excl_anses": [], "pre_qst_prompt": "", "additional_text": [], "post_qst_prompt": "", "original_options": [{"op_id": 0, "op_cid": "01", "op_body": "要檢查", "op_head": "(01) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}, {"op_id": 1, "op_cid": "02", "op_body": "不用檢查", "op_head": "(02) ", "op_note": "", "op_group": 1, "op_width": 1.0, "op_body_color": "", "op_head_color": ""}], "num_opts_each_line": 1, "post_options_prompt": "** 為免資料流失，請「不要直接關閉瀏覽器」，謝謝。**", "allow_repeated_anses": false}]}$$, $${"rnd_qs": [], "exports": [], "imports": [], "must_qs": [], "pastings": [], "mut_excls": [], "branchings": [], "calculations": [], "option_quotas": [], "rnd_skipped_qs": [], "system_missing": "9", "dynamic_options": [], "fixed_skipped_qs": [], "ignore_gender_lang": false, "household_selection": [], "completion_threshold": 46}$$, false, false, false, 3, '', '#123895', '#987450', false, false, ARRAY['校友', '台大', '就業'], 'C', true, '');


-- --
---- 訪問結果(含答案)(drop existing table first)
DROP TABLE IF EXISTS :schema.results CASCADE;
-- Recreate the :schema.results table
CREATE TABLE :schema.results (
    id                            serial PRIMARY KEY,
    project_id                    integer NOT NULL,
    questionnaire_id              integer NOT NULL,
    qre_version                   smallint NOT NULL CHECK (qre_version >= -1 AND qre_version <= 9999),
    resp_cid                      varchar(50) NOT NULL,
    tel_ori                       varchar(50),
    tel_type                      char(1),
    tel_area                      char(1),
    seq_number                    integer NOT NULL CHECK (seq_number >= 1),
    outcome_cid_raw               varchar(8) NOT NULL,
    outcome_cid_final             varchar(8) NOT NULL,
    nth_attempt                   smallint NOT NULL DEFAULT 1 CHECK (nth_attempt >= 1 AND nth_attempt <= 1000),
    dial_cid                      char(1),
    interviewer_id                varchar(12),
    gender                        char(1),
    language_cid                  char(2),
    quota_cid                     varchar(8),
    conducted_on                  date NOT NULL,
    started_at                    timestamp with time zone,
    ended_at                      timestamp with time zone,
    num_sys_qsts                  smallint NOT NULL,
    num_sys_qsts_done             smallint NOT NULL,
    num_user_qsts                 smallint NOT NULL,
    num_user_qsts_done            smallint NOT NULL,
    total_len_anses               integer,
    completion_threshold          smallint,
    refusal_reason_cid            char(2),
    human_contact_status          char(1),
    eligible_contact_status       char(1),
    appt_type                     char(1),
    appt_days                     smallint CHECK (appt_days >= 0 AND appt_days <= 1096),
    appt_scheduled_at             timestamp with time zone,
    appt_reason                   char(2),
    appt_remarks                  varchar(1000),
    hws_type                      char(1),
    hws_eligible_str              varchar(50),
    hws_m_f                       char(1),
    hws_tel_wgt                   char(1),
    hws_allow_subst               boolean,
    hws_num_eligibles             smallint CHECK (hws_num_eligibles >= 0 AND hws_num_eligibles <= 30),
    hws_num_males                 smallint CHECK (hws_num_males >= 0 AND hws_num_males <= 30),
    hws_designated_order          smallint CHECK (hws_designated_order >= 0 AND hws_designated_order <= 30),
    hws_designated_str            varchar(100),
    hws_nth_priority              smallint CHECK (hws_nth_priority >= 1 AND hws_nth_priority <= 15),
    hws_is_first_contact_matched  boolean,
    hws_designated_contact_status char(1) CHECK ((hws_designated_contact_status >= '0' AND hws_designated_contact_status <= '2') OR (hws_designated_contact_status = '9')),
    difficulty                    smallint CHECK (difficulty >= 1 AND difficulty <= 10),
    sample_info                   jsonb,
    outcome_remarks               varchar(1000),
    sys_qst_order                 jsonb NOT NULL,
    answers                       jsonb NOT NULL,
    fixed_vars                    jsonb,
    tags                          varchar(50)[],
    created_at                    timestamp with time zone NOT NULL DEFAULT now(),
    updated_at                    timestamp with time zone NOT NULL DEFAULT now(),
    status                        varchar(50),
    is_active                     boolean DEFAULT true,
    CONSTRAINT fk_results_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_results_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.results IS '訪問結果(含答案)raw data表';

COMMENT ON COLUMN :schema.results.id                            IS '系統自動累加的id';
COMMENT ON COLUMN :schema.results.project_id                    IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.results.questionnaire_id              IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.results.qre_version                   IS '問卷版本(範圍1-9999)';
COMMENT ON COLUMN :schema.results.resp_cid                      IS '電訪：電話號碼；網路：受訪者id';
COMMENT ON COLUMN :schema.results.tel_ori                       IS '(電訪only)原電話號碼';
COMMENT ON COLUMN :schema.results.tel_type                      IS '(電訪only)電話號碼類型："A" 住宅電話(抽樣)  "B" 機構電話(抽樣)  "C" 手機(抽樣)  "M" 住宅電話(匯入)  "N" 機構電話(匯入)  "O" 手機(滙入)  "P 其他匯入電話';
COMMENT ON COLUMN :schema.results.tel_area                      IS '(電訪only)電話所在地區："L" 本地  "O" 外地(不同country calling code)';
COMMENT ON COLUMN :schema.results.seq_number                    IS '每份問卷的每一筆訪問/填答資料的序號，每份問卷都從1開始編號。注意：本欄是「筆數」而非「樣本」流水號';
COMMENT ON COLUMN :schema.results.outcome_cid_raw               IS '原始訪問/填答結果代碼。電話訪問時為撥號結果設定表中的「撥號結果代碼(outcome_cid)」，訪問完成時依撥號結果表中撥號代碼的長度，定為若干個"0"("00", "0000"...，)；網路調查則固定以"00"表填答完成，"99"表未填完';
COMMENT ON COLUMN :schema.results.outcome_cid_final             IS '調整後的訪問或填答結果代碼(多半是因「完成題數」而將原本「未完成」調整為「完成」)';
COMMENT ON COLUMN :schema.results.nth_attempt                   IS '電訪：第幾次撥號，2表第1次重撥；網路：第幾次填答，2表第1次續填。範圍1-500';
COMMENT ON COLUMN :schema.results.dial_cid                      IS '(電訪only)撥出方式代碼';
COMMENT ON COLUMN :schema.results.interviewer_id                IS '(電訪only)訪員編號';
COMMENT ON COLUMN :schema.results.gender                        IS '(電訪only)受訪者性別';
COMMENT ON COLUMN :schema.results.language_cid                  IS '(電訪only)訪問所用語言';
COMMENT ON COLUMN :schema.results.quota_cid                     IS '樣本配額層別代碼';
COMMENT ON COLUMN :schema.results.conducted_on                  IS '訪問日期';
COMMENT ON COLUMN :schema.results.started_at                    IS '開始時間';
COMMENT ON COLUMN :schema.results.ended_at                      IS '結束時間';
COMMENT ON COLUMN :schema.results.num_sys_qsts                  IS '總「系統」題數';
COMMENT ON COLUMN :schema.results.num_sys_qsts_done             IS '已完成「系統」題數';
COMMENT ON COLUMN :schema.results.num_user_qsts                 IS '總「使用者」題數';
COMMENT ON COLUMN :schema.results.num_user_qsts_done            IS '已完成「使用者」題數(如無「隨機題目」，本欄約略等於在哪一題中止訪問/填答)';
COMMENT ON COLUMN :schema.results.total_len_anses               IS '各題答案的總長度';
COMMENT ON COLUMN :schema.results.completion_threshold          IS '「完成題數」設定(注意：本欄就是Q檔上「完成題數」的設定值，並非實際已完成的題數)';
COMMENT ON COLUMN :schema.results.refusal_reason_cid            IS '(電訪only)拒訪原因';
COMMENT ON COLUMN :schema.results.human_contact_status          IS '(電訪only)是否接觸到「人」："0": 一定不會接觸到合格受訪者；"1": 有可能接觸到人；"2": 肯定接觸到人；"9": 無法判斷';
COMMENT ON COLUMN :schema.results.eligible_contact_status       IS '(電訪only，無戶內抽樣時)合格受訪者接觸情形："0": 一定不會接觸到合格受訪者；"1": 有可能接觸到合格受訪者；"2": 肯定接觸到合格受訪者；"9": 無法判斷';
COMMENT ON COLUMN :schema.results.appt_type                     IS '(電訪only)約訪方式';
COMMENT ON COLUMN :schema.results.appt_days                     IS '(電訪only)約訪訂在多少天後。當天為0，第二天為1...(範圍0-1096)';
COMMENT ON COLUMN :schema.results.appt_scheduled_at             IS '(電訪only)約訪時間';
COMMENT ON COLUMN :schema.results.appt_reason                   IS '(電訪only)約訪原因';
COMMENT ON COLUMN :schema.results.appt_remarks                  IS '(電訪only)約訪備註';
COMMENT ON COLUMN :schema.results.hws_type                      IS '(電訪only)戶內抽樣：抽樣方法';
COMMENT ON COLUMN :schema.results.hws_eligible_str              IS '(電訪only)戶內抽樣：合格者字串(如"二十歲以上且戶籍在宜蘭縣者"、"年滿十八歲的香港永久居民")';
COMMENT ON COLUMN :schema.results.hws_m_f                       IS '(電訪only)戶內抽樣：詢問男性(M)或女性(F)人數';
COMMENT ON COLUMN :schema.results.hws_tel_wgt                   IS '(電訪only)戶內抽樣：以電話尾數(T)或權數(W)為依據找出指定受訪者';
COMMENT ON COLUMN :schema.results.hws_allow_subst               IS '(電訪only)戶內抽樣：是否允許替換指定受訪者';
COMMENT ON COLUMN :schema.results.hws_num_eligibles             IS '(電訪only)戶內抽樣：戶內「合格者」人數(範圍0-30)';
COMMENT ON COLUMN :schema.results.hws_num_males                 IS '(電訪only)戶內抽樣：戶內合格者中的「男性」人數(範圍0-30)';
COMMENT ON COLUMN :schema.results.hws_designated_order          IS '(電訪only)戶內抽樣：指定受訪者按「先女後男，先大後小」規則排列的序號(範圍0-30)。例一：合格人數5，女性數2，隨機亂數(即指定受訪者代號)=4，字串為「年齡次小的男性」；例二：合格人數4，女性數3，隨機亂數=1，指定受訪者字串為「年齡最大的女性」；例三：合格人數3，女性數2，隨機亂數=3，指定受訪者字串為「唯一的男性」';
COMMENT ON COLUMN :schema.results.hws_designated_str            IS '(電訪only)戶內抽樣：指定受訪者字串(如"年齡次小的男性"、"唯一女性")';
COMMENT ON COLUMN :schema.results.hws_nth_priority              IS '(電訪only)戶內抽樣：最終受訪者是第幾順位。1表第1順位，2表第2順位即更換過一次(範圍1-15)';
COMMENT ON COLUMN :schema.results.hws_is_first_contact_matched  IS '(電訪only)戶內抽樣：第一個接話者是否即為第1順位的指定受訪者';
COMMENT ON COLUMN :schema.results.hws_designated_contact_status IS '(電訪only)戶內抽樣：是否接觸到第1順位的指定受訪者："0": 一定不會接觸到；"1": 有可能接觸到；"2": 肯定接觸到；"9": 無法判斷';
COMMENT ON COLUMN :schema.results.difficulty                    IS '問卷難度';
COMMENT ON COLUMN :schema.results.sample_info                   IS '樣本資訊';
COMMENT ON COLUMN :schema.results.outcome_remarks               IS '(電訪only)撥號結果備註';
COMMENT ON COLUMN :schema.results.sys_qst_order                 IS '系統題目次序';
COMMENT ON COLUMN :schema.results.answers                       IS '各題答案';
COMMENT ON COLUMN :schema.results.fixed_vars                    IS '固定欄位變數(variables)，例如edu, age, area, marriage, income, native, party, ...等，可作跨調查研究使用。變數個數不限，實際上有哪些變數以及每個變數的選項，均由使用者自行定義';
COMMENT ON COLUMN :schema.results.tags                          IS '標籤';
COMMENT ON COLUMN :schema.results.created_at                    IS '建立時間';
COMMENT ON COLUMN :schema.results.updated_at                    IS '最後修改時間';
COMMENT ON COLUMN :schema.results.status                        IS '狀態';
COMMENT ON COLUMN :schema.results.is_active                     IS '是否啟用';

-- 建立results table的索引
DROP INDEX IF EXISTS idx_results_resp_cid;
CREATE INDEX idx_results_resp_cid          ON :schema.results(resp_cid);
DROP INDEX IF EXISTS idx_results_outcome_cid_final;
CREATE INDEX idx_results_outcome_cid_final ON :schema.results(outcome_cid_final);
DROP INDEX IF EXISTS idx_results_qre_version;
CREATE INDEX idx_results_qre_version       ON :schema.results(qre_version);
DROP INDEX IF EXISTS gin_results_answers;
CREATE INDEX gin_results_answers           ON :schema.results USING GIN (answers);
COMMENT ON INDEX :schema.idx_results_resp_cid          IS '電話號碼/受訪者id索引';
COMMENT ON INDEX :schema.idx_results_outcome_cid_final IS '訪問結果代碼索引';
COMMENT ON INDEX :schema.idx_results_qre_version       IS '問卷版本索引';
COMMENT ON INDEX :schema.gin_results_answers           IS '各題答案索引';
COMMENT ON INDEX :schema.results_pkey                  IS '訪問結果raw data table的PK索引，由系統自動建立';


-- --
---- 百分比及其他統計(drop existing table first)
DROP TABLE IF EXISTS :schema.ans_stats CASCADE;
-- Recreate the :schema.ans_stats table
CREATE TABLE :schema.ans_stats (
    id               serial PRIMARY KEY,
    project_id       integer NOT NULL,
    questionnaire_id integer NOT NULL,
    qre_version      smallint NOT NULL CHECK (qre_version >= -1 AND qre_version <= 9999),
    quota_cid        varchar(8) NOT NULL,
    user_qst_cid     smallint NOT NULL,
    option_cid       varchar(10) NOT NULL,
    frequency        integer NOT NULL,
    percent          DECIMAL(8, 2) NOT NULL,
    aggregations     jsonb,
    CONSTRAINT fk_ans_stats_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_ans_stats_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.ans_stats IS '百分比及其他統計量資料表';

COMMENT ON COLUMN :schema.ans_stats.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.ans_stats.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.ans_stats.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.ans_stats.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.ans_stats.quota_cid        IS '樣本配額層別代碼';
COMMENT ON COLUMN :schema.ans_stats.user_qst_cid     IS '使用者題號';
COMMENT ON COLUMN :schema.ans_stats.option_cid       IS '選項代碼';
COMMENT ON COLUMN :schema.ans_stats.frequency        IS '次數';
COMMENT ON COLUMN :schema.ans_stats.percent          IS '百分比';
COMMENT ON COLUMN :schema.ans_stats.aggregations     IS '其他統計量(mean, median, mode, standard deviation...)';

DROP INDEX IF EXISTS idx_ans_stats_qre_version;
CREATE INDEX idx_ans_stats_qre_version  ON :schema.ans_stats(qre_version);
DROP INDEX IF EXISTS idx_ans_stats_user_qst_cid;
CREATE INDEX idx_ans_stats_user_qst_cid ON :schema.ans_stats(user_qst_cid);
DROP INDEX IF EXISTS idx_ans_stats_option_cid;
CREATE INDEX idx_ans_stats_option_cid   ON :schema.ans_stats(option_cid);
COMMENT ON INDEX :schema.idx_ans_stats_qre_version  IS '問卷版本索引';
COMMENT ON INDEX :schema.idx_ans_stats_user_qst_cid IS '(使用者)題號索引';
COMMENT ON INDEX :schema.idx_ans_stats_option_cid   IS '答案代碼索引';
COMMENT ON INDEX :schema.ans_stats_pkey             IS '百分比及其他統計量table的PK索引，由系統自動建立';


-- --
---- 專案樣本(drop existing table first)
DROP TABLE IF EXISTS :schema.samples CASCADE;
-- Recreate the :schema.samples table
CREATE TABLE :schema.samples (
    id               serial PRIMARY KEY,
    project_id       integer NOT NULL,
    questionnaire_id integer NOT NULL,
    category_cid     varchar(8),
    sample_cid       varchar(50) NOT NULL,
    info             jsonb,
    login_at         timestamp with time zone DEFAULT null,
    CONSTRAINT fk_samples_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_samples_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.samples IS '專案樣本表';

COMMENT ON COLUMN :schema.samples.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.samples.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.samples.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.samples.category_cid     IS '本筆樣本的類別或層別代碼，亦即配額表中的quota_cid。一般住宅樣本多半為縣市+鄉鎮市區代碼；其他樣本則視研究需求，可能是「科系代碼」、「障別代碼」、「職業代碼」...等。本欄和「配額表(quotas)」一起運作，用以控制各層別的完成比例';
COMMENT ON COLUMN :schema.samples.sample_cid       IS '樣本本身的id，如為電訪本欄為電話號碼，其他調查則為受訪者id，如身分證統一編號、學號、email...等，匿名網路調查時此id可能由系統隨機產生';
COMMENT ON COLUMN :schema.samples.info             IS '樣本資訊';
COMMENT ON COLUMN :schema.samples.login_at         IS '登入日期時間';


DROP INDEX IF EXISTS idx_samples_category_cid;
CREATE INDEX idx_samples_category_cid ON :schema.samples(category_cid);
DROP INDEX IF EXISTS idx_samples_sample_cid;
CREATE INDEX idx_samples_sample_cid   ON :schema.samples(sample_cid);
DROP INDEX IF EXISTS idx_samples_login_at;
CREATE INDEX idx_samples_login_at     ON :schema.samples(login_at);
DROP INDEX IF EXISTS gin_samples_info;
CREATE INDEX gin_samples_info         ON :schema.samples USING GIN (info);
COMMENT ON INDEX :schema.idx_samples_category_cid IS '樣本類別/層別索引';
COMMENT ON INDEX :schema.idx_samples_sample_cid   IS '樣本本身id(電話號碼或受訪者id)索引';
COMMENT ON INDEX :schema.gin_samples_info         IS '樣本資訊索引';
COMMENT ON INDEX :schema.idx_samples_login_at     IS '登入日期時間索引';
COMMENT ON INDEX :schema.samples_pkey             IS '專案樣本table的PK索引，由系統自動建立';


-- --
---- 配額(drop existing table first)
DROP TABLE IF EXISTS :schema.quotas CASCADE;
-- Recreate the :schema.quotas table
CREATE TABLE :schema.quotas (
    id                    serial PRIMARY KEY,
    project_id            integer NOT NULL,
    questionnaire_id      integer NOT NULL,
    qre_version           smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    quota_cid             varchar(8) NOT NULL,
    description           varchar(500) NOT NULL,
    quotas                integer NOT NULL,
    completions           integer NOT NULL,
    difference            integer NOT NULL,
    completion_rate       DECIMAL(5, 2) NOT NULL,
    allocation_rate       DECIMAL(5, 2) NOT NULL,
    completion_share      DECIMAL(5, 2) NOT NULL,
    difference_percentage DECIMAL(5, 2) NOT NULL,
    remains               integer NOT NULL,
    status                varchar(50),
    is_active             boolean,
    notes                 text,
    CONSTRAINT fk_quotas_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_quotas_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.quotas IS '配額表';

COMMENT ON COLUMN :schema.quotas.id                    IS '系統自動累加的id';
COMMENT ON COLUMN :schema.quotas.project_id            IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.quotas.questionnaire_id      IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.quotas.qre_version           IS '問卷版本';
COMMENT ON COLUMN :schema.quotas.quota_cid             IS '層別代碼';
COMMENT ON COLUMN :schema.quotas.description           IS '層別說明';
COMMENT ON COLUMN :schema.quotas.quotas                IS '配額數';
COMMENT ON COLUMN :schema.quotas.completions           IS '完成數';
COMMENT ON COLUMN :schema.quotas.difference            IS '差額(quotas - completions)';
COMMENT ON COLUMN :schema.quotas.completion_rate       IS '完成率(completions / quotas)';
COMMENT ON COLUMN :schema.quotas.allocation_rate       IS '分配率(quotas / total quotas)';
COMMENT ON COLUMN :schema.quotas.completion_share      IS '完成比重(completions / total completions)';
COMMENT ON COLUMN :schema.quotas.difference_percentage IS '分配率和完成比重之差(單位：百分點)';
COMMENT ON COLUMN :schema.quotas.remains               IS '剩餘電話樣本數';
COMMENT ON COLUMN :schema.quotas.status                IS '狀態';
COMMENT ON COLUMN :schema.quotas.is_active             IS '是否啟用';
COMMENT ON COLUMN :schema.quotas.notes                 IS '備註';

DROP INDEX IF EXISTS idx_quotas_quota_cid;
CREATE INDEX idx_quotas_quota_cid ON :schema.quotas(quota_cid);
COMMENT ON INDEX :schema.idx_quotas_quota_cid IS '自訂層別代碼索引';
COMMENT ON INDEX :schema.quotas_pkey          IS '配額table的PK索引，由系統自動建立';


-- --
---- 電話黑名單(drop existing table first)
DROP TABLE IF EXISTS :schema.blacks CASCADE;
-- Recreate the :schema.blacks table
CREATE TABLE :schema.blacks (
    id            serial PRIMARY KEY,
    tel           varchar(30) NOT NULL,
    expired_on    date NOT NULL,
    saved_on      date NOT NULL DEFAULT CURRENT_DATE,
    standard_code char(1)
);
COMMENT ON TABLE :schema.blacks IS '電話黑名單表';

COMMENT ON COLUMN :schema.blacks.id            IS '系統自動累加的id';
COMMENT ON COLUMN :schema.blacks.tel           IS '電話號碼';
COMMENT ON COLUMN :schema.blacks.expired_on    IS '有效日期';
COMMENT ON COLUMN :schema.blacks.saved_on      IS '存入日期';
COMMENT ON COLUMN :schema.blacks.standard_code IS '黑名單標準交換碼：不同問卷的撥號結果意義可能不同，須定義一組交換碼作為各調查的共通標準："A": 空號；"B": 非住宅；"C": 傳真機；"D": 故障、停話、改號';

-- 建立blacks table的索引
DROP INDEX IF EXISTS idx_blacks_tel;
CREATE INDEX idx_blacks_tel        ON :schema.blacks(tel);
DROP INDEX IF EXISTS idx_blacks_expired_on;
CREATE INDEX idx_blacks_expired_on ON :schema.blacks(expired_on);
COMMENT ON INDEX :schema.idx_blacks_tel        IS '電話號碼索引';
COMMENT ON INDEX :schema.idx_blacks_expired_on IS '有效日期索引';
COMMENT ON INDEX :schema.blacks_pkey           IS '電話黑名單table的PK索引，由系統自動建立';

-- Insert data into :schema.blacks
INSERT INTO :schema.blacks (tel, expired_on, standard_code) VALUES
('02-23807729', '2025-03-11', 'B'),
('02-24135194', '2025-01-05', 'A'),
('02-24233599', '2026-06-25', 'A'),
('02-24315698', '2025-07-12', 'C'),
('02-25800352', '2026-08-20', 'B'),
('02-26752309', '2027-07-14', 'C'),
('02-26903050', '2024-07-13', 'A'),
('02-27003466', '2025-05-04', 'D'),
('02-27356204', '2026-01-25', 'D'),
('02-27452102', '2028-04-11', 'D'),
('02-27789524', '2024-12-10', 'D'),
('02-27120302', '2024-11-09', 'D'),
('02-27525217', '2026-06-20', 'D'),
('02-27632540', '2024-08-17', 'D'),
('02-27474142', '2027-02-15', 'D'),
('02-27264751', '2026-10-30', 'B'),
('02-27358748', '2024-10-26', 'A'),
('02-27854798', '2029-01-16', 'B'),
('02-29474115', '2030-10-01', 'B'),
('02-31845024', '2026-05-28', 'A'),
('02-32714707', '2027-03-25', 'A'),
('02-33728514', '2028-04-12', 'C'),
('02-37285050', '2026-09-26', 'B'),
('02-38205001', '2024-11-16', 'C'),
('02-42157208', '2026-03-01', 'A'),
('02-44699955', '2028-01-28', 'D'),
('02-44818057', '2029-06-25', 'C'),
('02-44961764', '2032-07-12', 'B'),
('02-45587399', '2031-08-20', 'C'),
('02-45789444', '2029-07-14', 'A'),
('02-46088935', '2025-07-13', 'D'),
('02-46271285', '2025-03-04', 'B'),
('02-49316403', '2025-10-30', 'A'),
('02-51713498', '2025-10-26', 'B'),
('02-52128100', '2025-01-16', 'C'),
('02-52288102', '2025-10-01', 'A'),
('02-56431029', '2026-03-28', 'D'),
('02-59712317', '2025-01-25', 'B'),
('02-59815062', '2026-06-12', 'A'),
('02-65358489', '2027-07-20', 'B'),
('02-68596888', '2024-08-14', 'B'),
('02-69452368', '2025-07-13', 'A'),
('02-70143908', '2026-07-04', 'A'),
('02-70430327', '2028-03-30', 'C'),
('02-75427079', '2024-10-26', 'B'),
('02-76389930', '2024-10-16', 'C'),
('02-78464969', '2026-01-01', 'A'),
('02-78501500', '2024-10-28', 'D'),
('02-84428574', '2027-05-25', 'B'),
('02-85607431', '2026-03-20', 'A'),
('02-86593464', '2024-04-14', 'B'),
('03-2369834' , '2029-09-13', 'B'),
('03-2389305' , '2030-11-04', 'A'),
('03-2418733' , '2026-03-30', 'A'),
('03-2462166' , '2027-01-26', 'C'),
('03-2780035' , '2028-06-16', 'B'),
('03-3073820' , '2026-07-01', 'C'),
('03-3119960' , '2024-08-28', 'A'),
('03-3213162' , '2026-07-25', 'D'),
('03-3303809' , '2028-07-12', 'B'),
('03-3885666' , '2029-03-20', 'A'),
('03-3909635' , '2032-10-14', 'B'),
('03-4090261' , '2031-10-13', 'B'),
('03-4315613' , '2029-01-04', 'A'),
('03-4463672' , '2025-10-30', 'A'),
('03-4482956' , '2025-05-26', 'C'),
('03-4787792' , '2025-03-16', 'B'),
('03-4804861' , '2025-04-01', 'B'),
('03-5435563' , '2025-09-28', 'A'),
('03-5449575' , '2025-11-25', 'A'),
('03-5783629' , '2025-03-12', 'C'),
('03-5986329' , '2025-01-20', 'B'),
('03-6082241' , '2025-06-14', 'C'),
('03-6127685' , '2025-07-13', 'A'),
('03-6325453' , '2025-08-04', 'D'),
('03-6545597' , '2025-07-30', 'B'),
('03-6599759' , '2025-07-26', 'A'),
('03-6831299' , '2025-03-16', 'B'),
('03-6842051' , '2025-10-01', 'B'),
('03-8186621' , '2025-10-28', 'A'),
('03-8608606' , '2025-01-25', 'A'),
('03-8792997' , '2025-10-12', 'C'),
('03-8795295' , '2026-03-20', 'B'),
('037-207117' , '2025-01-14', 'C'),
('037-218443' , '2026-06-13', 'A'),
('037-250094' , '2027-07-04', 'D'),
('037-291470' , '2024-08-30', 'B'),
('037-294376' , '2025-07-26', 'A'),
('037-315719' , '2026-07-16', 'B'),
('037-328265' , '2028-03-01', 'B'),
('037-375462' , '2024-10-28', 'A'),
('037-380254' , '2024-10-25', 'A'),
('037-386741' , '2026-01-12', 'C'),
('037-391129' , '2024-10-25', 'B'),
('037-396663' , '2027-05-12', 'C'),
('037-396861' , '2026-03-20', 'A'),
('037-416663' , '2024-04-14', 'D'),
('037-436703' , '2029-09-13', 'C'),
('037-447255' , '2030-11-04', 'B'),
('037-461346' , '2026-03-30', 'C'),
('037-486213' , '2027-01-26', 'A'),
('037-530611' , '2028-06-16', 'D'),
('037-531666' , '2026-07-01', 'B'),
('037-550783' , '2024-08-28', 'A'),
('037-554688' , '2026-07-25', 'B'),
('037-572712' , '2028-07-12', 'C'),
('037-579122' , '2029-03-26', 'A'),
('037-587209' , '2032-10-16', 'D'),
('037-594462' , '2031-10-01', 'B'),
('037-599209' , '2029-01-28', 'A'),
('037-615165' , '2025-10-25', 'B'),
('037-641123' , '2025-05-12', 'C'),
('037-664349' , '2025-03-20', 'A'),
('037-666819' , '2025-04-14', 'D'),
('037-674890' , '2025-07-13', 'B'),
('037-679046' , '2025-07-04', 'A'),
('037-688660' , '2026-03-30', 'B'),
('037-721424' , '2025-10-26', 'B'),
('037-753516' , '2026-10-16', 'A'),
('037-773678' , '2027-01-01', 'A'),
('037-793973' , '2024-10-28', 'C'),
('037-848410' , '2025-05-25', 'B'),
('037-859291' , '2026-03-12', 'C'),
('037-861363' , '2028-04-20', 'A'),
('037-873621' , '2024-10-14', 'D'),
('037-883873' , '2024-10-13', 'B'),
('037-887290' , '2026-01-04', 'A'),
('037-887302' , '2024-10-30', 'B'),
('04-21369139', '2027-05-26', 'B'),
('04-27382032', '2026-03-16', 'A'),
('04-27799469', '2024-04-01', 'A'),
('04-28571783', '2029-09-28', 'C'),
('04-30033757', '2030-11-25', 'B'),
('04-33176081', '2026-03-20', 'C'),
('04-33707467', '2027-01-14', 'A'),
('04-34025377', '2028-06-13', 'D'),
('04-39679715', '2026-07-04', 'B'),
('04-43526344', '2024-08-30', 'A'),
('04-50162709', '2026-07-26', 'B'),
('04-51817984', '2028-07-16', 'A'),
('04-54154436', '2029-03-01', 'A'),
('04-54522554', '2032-10-28', 'C'),
('04-55207710', '2031-10-25', 'B'),
('04-55262938', '2029-01-12', 'C'),
('04-55534832', '2025-10-20', 'A'),
('04-56659322', '2025-05-14', 'D'),
('04-58152502', '2025-03-13', 'B'),
('04-62694187', '2025-04-04', 'A'),
('04-63801244', '2025-05-30', 'B'),
('04-68312779', '2025-05-26', 'B'),
('04-69217352', '2025-05-16', 'A'),
('04-7077711' , '2025-03-01', 'A'),
('04-7215051' , '2025-04-28', 'C'),
('04-7248685' , '2025-09-25', 'B'),
('04-7423041' , '2025-11-12', 'C'),
('04-7528330' , '2025-03-20', 'A'),
('04-7553538' , '2025-01-14', 'D'),
('04-7610788' , '2025-06-13', 'B'),
('04-8089540' , '2025-07-04', 'A'),
('04-8146844' , '2025-08-30', 'B'),
('04-8146944' , '2025-07-26', 'B'),
('04-8359178' , '2025-07-16', 'A'),
('04-8760023' , '2025-03-01', 'A'),
('04-8868443' , '2025-10-28', 'C'),
('04-8871853' , '2025-10-25', 'B'),
('05-2055625' , '2025-01-12', 'C'),
('05-2313901' , '2025-10-20', 'A'),
('05-2554354' , '2025-03-14', 'D'),
('05-3585851' , '2025-01-13', 'B'),
('05-3824401' , '2025-06-04', 'A'),
('05-4123623' , '2025-07-30', 'C'),
('05-4153650' , '2025-08-26', 'B'),
('05-4157431' , '2025-07-25', 'C'),
('05-4159076' , '2025-07-12', 'A'),
('05-4471830' , '2025-03-20', 'D'),
('05-4724946' , '2025-10-14', 'B'),
('05-5273025' , '2025-10-13', 'A'),
('05-5830393' , '2025-01-04', 'A'),
('05-5831903' , '2025-10-30', 'D'),
('05-5870340' , '2025-05-26', 'B'),
('05-5888255' , '2025-03-16', 'A'),
('05-5970715' , '2025-04-01', 'B'),
('05-6354225' , '2025-09-28', 'B'),
('05-6375954' , '2025-11-25', 'B'),
('05-6428387' , '2025-03-12', 'A'),
('05-6620942' , '2025-01-26', 'A'),
('05-6686498' , '2025-06-16', 'C'),
('05-6979388' , '2025-07-01', 'B'),
('05-7059175' , '2025-08-28', 'C'),
('05-7810185' , '2025-07-25', 'A'),
('05-8308476' , '2025-07-12', 'D'),
('05-8493891' , '2025-03-20', 'B'),
('05-8528708' , '2025-10-14', 'A'),
('05-8690200' , '2025-10-13', 'B'),
('05-8690675' , '2025-01-04', 'B'),
('05-8721257' , '2025-10-30', 'A'),
('05-8903013' , '2025-05-26', 'A'),
('06-2206983' , '2025-03-16', 'A'),
('06-2322739' , '2025-04-01', 'D'),
('06-2387933' , '2025-05-28', 'B'),
('06-2694824' , '2025-05-25', 'A'),
('06-2765125' , '2025-10-12', 'B'),
('06-2773233' , '2025-01-20', 'B'),
('06-3466704' , '2025-10-14', 'A'),
('06-3633237' , '2025-03-13', 'B'),
('06-3908233' , '2025-01-04', 'B'),
('06-4407105' , '2025-06-30', 'A'),
('06-4430922' , '2025-07-26', 'A'),
('06-4611461' , '2025-08-16', 'C'),
('06-4905770' , '2025-07-01', 'B'),
('06-4947439' , '2025-07-28', 'C'),
('06-5317191' , '2025-03-25', 'A'),
('06-5570024' , '2025-10-20', 'D'),
('06-6356324' , '2025-10-14', 'B'),
('06-6494073' , '2025-01-13', 'A'),
('06-6665964' , '2025-10-04', 'B'),
('06-6680195' , '2025-05-30', 'B'),
('06-6726022' , '2025-03-26', 'A'),
('06-6768301' , '2026-04-16', 'A'),
('06-7033222' , '2025-09-01', 'C'),
('06-7045673' , '2026-11-28', 'B'),
('06-7087816' , '2027-03-25', 'C'),
('06-7096848' , '2024-01-12', 'A'),
('06-7119519' , '2025-06-20', 'D'),
('06-7215975' , '2026-07-14', 'B'),
('06-7252089' , '2028-08-13', 'A'),
('06-7277490' , '2024-07-04', 'B'),
('06-7326134' , '2024-07-30', 'B'),
('06-7331980' , '2026-03-26', 'A'),
('06-7461663' , '2024-10-16', 'A'),
('06-7560168' , '2027-10-01', 'C'),
('06-7724494' , '2026-01-28', 'B'),
('06-8249027' , '2024-10-25', 'C'),
('06-8745810' , '2029-05-12', 'A'),
('06-8819110' , '2030-03-20', 'D'),
('06-8902611' , '2026-04-14', 'A'),
('07-2167540' , '2027-07-13', 'D'),
('07-2385402' , '2028-07-04', 'B'),
('07-2394580' , '2026-03-30', 'A'),
('07-2740889' , '2024-10-26', 'B'),
('07-2816818' , '2026-10-16', 'B'),
('07-2946442' , '2028-01-01', 'A'),
('07-3066690' , '2029-10-28', 'B'),
('07-3449897' , '2032-05-25', 'C'),
('07-3542623' , '2031-03-12', 'A'),
('07-4043535' , '2029-04-20', 'D'),
('07-4192711' , '2025-10-14', 'B'),
('07-4207028' , '2025-10-13', 'A'),
('07-4756813' , '2025-01-04', 'B'),
('07-4817243' , '2025-10-30', 'B'),
('07-5073378' , '2025-05-26', 'A'),
('07-5161460' , '2025-03-16', 'A'),
('07-5221151' , '2025-04-01', 'C'),
('07-5447191' , '2025-09-28', 'B'),
('07-5523069' , '2025-11-25', 'C'),
('07-5674669' , '2025-03-12', 'A'),
('07-5778298' , '2025-01-12', 'D'),
('07-5796430' , '2025-06-20', 'B'),
('07-6286470' , '2025-07-14', 'B'),
('07-6468841' , '2025-08-13', 'A'),
('07-6485863' , '2025-07-04', 'A'),
('07-6625084' , '2025-07-30', 'C'),
('07-6673462' , '2025-03-26', 'B'),
('07-6703775' , '2025-10-16', 'C'),
('07-6870835' , '2025-10-01', 'A'),
('07-6885690' , '2025-01-28', 'D'),
('07-7133509' , '2025-10-25', 'B'),
('07-8027356' , '2025-05-12', 'A'),
('07-8280483' , '2025-03-20', 'B'),
('07-8621305' , '2025-04-14', 'B'),
('07-8961191' , '2025-05-13', 'A'),
('07-8971548' , '2025-10-04', 'A'),
('08-2040512' , '2025-01-30', 'C'),
('08-2244904' , '2025-10-26', 'B'),
('08-2396029' , '2025-05-16', 'C'),
('08-2828109' , '2025-03-01', 'B'),
('08-2950017' , '2025-04-28', 'B'),
('08-2953585' , '2025-10-25', 'A'),
('08-3093493' , '2025-10-12', 'A'),
('08-3237531' , '2025-01-20', 'C'),
('08-3253553' , '2025-10-14', 'B'),
('08-3401677' , '2025-05-13', 'C'),
('08-4484041' , '2026-03-04', 'A'),
('08-4865117' , '2027-04-30', 'D'),
('08-4879269' , '2025-09-26', 'B'),
('08-4891069' , '2024-11-16', 'A'),
('08-5446280' , '2030-03-01', 'B'),
('08-5696172' , '2029-01-28', 'B'),
('08-6039301' , '2028-06-25', 'A'),
('08-6455407' , '2027-07-12', 'A'),
('08-6470311' , '2025-08-20', 'C'),
('08-6684881' , '2024-07-14', 'A'),
('08-6711876' , '2026-07-13', 'D'),
('08-7053383' , '2025-03-04', 'B'),
('08-7087659' , '2027-10-30', 'A'),
('08-7245970' , '2029-10-26', 'B'),
('08-7351800' , '2035-01-16', 'B'),
('08-7527374' , '2034-10-01', 'A'),
('082-198150' , '2025-05-28', 'A'),
('082-433630' , '2029-03-25', 'B'),
('089-834754' , '2030-04-12', 'B'),
('089-963607' , '2025-05-05', 'A');


-- --
---- 撥號結果設定(drop existing table first)
DROP TABLE IF EXISTS :schema.outcomes CASCADE;
-- Recreate the :schema.outcomes table
CREATE TABLE :schema.outcomes (
    id                      serial PRIMARY KEY,
    project_id              integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id        integer,
    qre_version             smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    outcome_cid             varchar(8) NOT NULL,
    description             varchar(500) NOT NULL,
    timing                  char(1) NOT NULL,
    need_callback           boolean NOT NULL,
    need_block              boolean NOT NULL,
    refusal_type            char(1) NOT NULL,
    appointment_type        char(1) NOT NULL,
    blacks_banned_days      smallint DEFAULT 0 CHECK ((blacks_banned_days >= 0 AND blacks_banned_days <= 36525) OR (blacks_banned_days = 99999)),
    blacks_standard_code    char(1) NOT NULL CHECK (blacks_standard_code = '' OR (blacks_standard_code >= 'A' AND blacks_standard_code <= 'D')),
    is_auto_revised         boolean NOT NULL DEFAULT true,
    has_remarks             boolean NOT NULL DEFAULT false,
    human_contact_status    char(1) CHECK ((human_contact_status >= '0' AND human_contact_status <= '2') OR (human_contact_status = '9')),
    eligible_contact_status char(1) CHECK ((eligible_contact_status >= '0' AND eligible_contact_status <= '2') OR (eligible_contact_status = '9')),
    notes                   text,
    CONSTRAINT fk_outcomes_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_outcomes_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.outcomes IS '撥號結果「設定」表';

COMMENT ON COLUMN :schema.outcomes.id                      IS '系統自動累加的id';
COMMENT ON COLUMN :schema.outcomes.project_id              IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.outcomes.questionnaire_id        IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.outcomes.qre_version             IS '問卷版本';
COMMENT ON COLUMN :schema.outcomes.outcome_cid             IS '撥號結果代碼';
COMMENT ON COLUMN :schema.outcomes.description             IS '撥號結果說明';
COMMENT ON COLUMN :schema.outcomes.timing                  IS '時機("1": 只在未輸入任何答案時出現；"2": 只在訪問中途(已輸入最少一個答案)出現；"3": 任何時機下均會出現。)';
COMMENT ON COLUMN :schema.outcomes.need_callback           IS '重撥：本門號是否須重撥';
COMMENT ON COLUMN :schema.outcomes.need_block              IS '攔阻：本門號如有重複，且「之前已有確定結果(即不要重撥)」，是否須發出警訊，詢問訪員要不要阻止撥出';
COMMENT ON COLUMN :schema.outcomes.refusal_type            IS '是否拒訪："0": 本撥號結果並非拒訪；"1": 訪問未正式開始前(未輸入任何答案)即遭拒訪；"2": 訪問中途(已輸入最少一個答案)遭拒訪';
COMMENT ON COLUMN :schema.outcomes.appointment_type        IS '是否約訪："0": 本撥號結果並非約訪；"1": 訪問未正式開始前(未輸入任何答案)約訪；"2": 訪問中途訪問中途(已輸入最少一個答案)約訪；"9": 本身非約訪，但上通如為約訪須續約';
COMMENT ON COLUMN :schema.outcomes.blacks_banned_days      IS '黑名單：小於或等於0時，表示本通門號並非黑名單；大於0的值代表本通門號屬於黑名單，而數字為門號保留在黑名單的期間，單位是天，有效範圍為1-36525(即最多100年)；特別值99999表示永久列入黑名單';
COMMENT ON COLUMN :schema.outcomes.blacks_standard_code    IS '黑名單標準交換碼：不同問卷的撥號結果意義可能不同，須定義一組交換碼作為各調查的共通標準："A": 空號；"B": 非住宅；"C": 傳真機；"D": 故障、停話、改號';
COMMENT ON COLUMN :schema.outcomes.is_auto_revised         IS '是否自動修正撥號結果代碼。通常是由於「完成題數」指令使原本「非完成」修正成「完成」';
COMMENT ON COLUMN :schema.outcomes.has_remarks             IS '是否需要備註';
COMMENT ON COLUMN :schema.outcomes.human_contact_status    IS '是否接觸到「人」："0": 一定不會接觸到人；"1": 有可能接觸到人；"2": 肯定接觸到人；"9": 無法判斷';
COMMENT ON COLUMN :schema.outcomes.eligible_contact_status IS '是否接觸到合格受訪者："0": 一定不會接觸到合格受訪者；"1": 有可能接觸到合格受訪者；"2": 肯定接觸到合格受訪者；"9": 無法判斷';
COMMENT ON COLUMN :schema.outcomes.notes                   IS '備註';

-- 建立outcomes table的索引
DROP INDEX IF EXISTS idx_outcomes_project_id;
CREATE INDEX idx_outcomes_project_id       ON :schema.outcomes(project_id);
DROP INDEX IF EXISTS idx_outcomes_questionnaire_id;
CREATE INDEX idx_outcomes_questionnaire_id ON :schema.outcomes(questionnaire_id);
DROP INDEX IF EXISTS idx_outcomes_qre_version;
CREATE INDEX idx_outcomes_qre_version      ON :schema.outcomes(qre_version);
COMMENT ON INDEX :schema.idx_outcomes_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_outcomes_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_outcomes_qre_version      IS '問卷版本索引';
COMMENT ON INDEX :schema.outcomes_pkey                 IS '撥號結果設定table的PK索引，由系統自動建立';

-- Insert data into :schema.outcomes
INSERT INTO :schema.outcomes (project_id, questionnaire_id, qre_version, outcome_cid, description, timing, need_callback, need_block, refusal_type, appointment_type, blacks_banned_days, blacks_standard_code, is_auto_revised, has_remarks, human_contact_status, eligible_contact_status, notes) VALUES
(null, null, 0, '01', '鈴響八次(約２４秒)，無人接聽',                           '1', true,  false, '0', '9',    0, '',  false, false, '0', '0', ''),
(null, null, 0, '02', '忙線',                                                   '1', true,  false, '0', '9',    0, '',  false, false, '0', '0', ''),
(null, null, 0, '03', '空號',                                                   '1', false, false, '1', '0', 1826, 'A', false, false, '0', '0', ''),
(null, null, 0, '04', '拒訪１：接話者拒訪，無法確定是否為合格受訪者',           '1', false, false, '1', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '05', '拒訪２：確定有合格受訪者，但拒絕接受訪問',               '1', false, false, '2', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '06', '拒訪３：受訪者中途拒訪',                                 '2', false, false, '0', '0',    0, '',  true,  false, '2', '2', ''),
(null, null, 0, '07', '合格或指定受訪者因生理或心理因素無法受訪',               '3', false, false, '0', '0',    0, '',  true,  false, '2', '1', ''),
(null, null, 0, '08', '合格或指定受訪者因語言因素無法受訪',                     '3', false, false, '0', '0',    0, '',  true,  false, '2', '1', ''),
(null, null, 0, '09', '約訪１：合格或指定受訪者不在或不便，另約時間',           '1', false, false, '0', '1',    0, '',  false, false, '2', '2', ''),
(null, null, 0, '10', '約訪２：訪問中途受訪者因故不便繼續，另約時間',           '2', false, false, '0', '2',    0, '',  false, false, '2', '2', ''),
(null, null, 0, '11', '配額已滿',                                               '3', false, false, '0', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '12', '有人接話但不確定是否為住宅(住商合一也算是住宅)',         '1', false, false, '0', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '13', '有人接話但不確定是否符合調查定義的範圍(如地區、身份)',   '1', false, false, '0', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '14', '本門號為住宅且符合調查定義的範圍，但無合格受訪者',       '1', false, false, '0', '0',    0, '',  false, false, '2', '0', ''),
(null, null, 0, '15', '不符調查定義的範圍(例如地區或身份不對)',                 '3', false, false, '0', '0',    0, '',  false, false, '2', '0', ''),
(null, null, 0, '16', '非住宅，如公司機構、宿舍或其他團體(含電話答錄)',         '3', false, false, '0', '0', 3652, 'B', false, false, '1', '0', ''),
(null, null, 0, '17', '(戶內抽樣)指定受訪者在訪問時間內無法接觸',               '1', false, false, '0', '0',    0, '',  false, false, '2', '9', ''),
(null, null, 0, '18', '傳真機',                                                 '1', false, false, '0', '9',  730, 'C', false, false, '0', '0', ''),
(null, null, 0, '19', '電話答錄，不確定是否為住宅',                             '1', false, false, '0', '0',    0, '',  false, false, '0', '0', ''),
(null, null, 0, '20', '電話答錄，確定為住宅',                                   '1', true,  false, '0', '9',    0, '',  false, false, '0', '0', ''),
(null, null, 0, '21', '電話答錄，確定為非住宅',                                 '1', false, false, '0', '0', 3652, 'B', false, false, '0', '0', ''),
(null, null, 0, '22', '電話故障、停話、改號等',                                 '1', false, false, '0', '0',  365, 'D', false, false, '9', '9', ''),
(null, null, 0, '23', '同一份問卷已問過',                                       '3', false, false, '0', '0',    0, '',  false, false, '2', '1', ''),
(null, null, 0, '98', '其他',                                                   '3', false, true,  '0', '0',    0, '',  true,  true,  '9', '9', '');


-- --
---- 拒訪原因設定(drop existing table first)
DROP TABLE IF EXISTS :schema.refusal_reasons CASCADE;
-- Recreate the :schema.refusal_reasons table
CREATE TABLE :schema.refusal_reasons (
    id               serial PRIMARY KEY,
    project_id       integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id integer,
    qre_version      smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    refusal_cid      varchar(8) NOT NULL,
    description      varchar(500) NOT NULL,
    notes            text,
    CONSTRAINT fk_refusal_reasons_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_refusal_reasons_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.refusal_reasons IS '拒訪原因「設定」表';

COMMENT ON COLUMN :schema.refusal_reasons.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.refusal_reasons.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.refusal_reasons.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.refusal_reasons.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.refusal_reasons.refusal_cid      IS '拒訪原因代碼';
COMMENT ON COLUMN :schema.refusal_reasons.description      IS '拒訪原因說明';
COMMENT ON COLUMN :schema.refusal_reasons.notes            IS '備註';

COMMENT ON INDEX :schema.refusal_reasons_pkey IS '拒訪原因設定table的PK索引，由系統自動建立';

-- Insert data into :schema.refusal_reasons
INSERT INTO :schema.refusal_reasons (project_id, questionnaire_id, qre_version, refusal_cid, description, notes) VALUES
(null, null, 0, '01', '太忙(在做別的事中)', ''),
(null, null, 0, '02', '對這次訪問的主題不感興趣或不熟悉', ''),
(null, null, 0, '03', '甚麼都不知道', ''),
(null, null, 0, '04', '過去受訪問經驗不愉快', ''),
(null, null, 0, '05', '覺得侵犯了個人隱私', ''),
(null, null, 0, '06', '拒絕以電話方式接受訪問(如要求到府面訪、郵寄、傳真、email問卷或上網填答等)', ''),
(null, null, 0, '07', '不相信真的是本機構在做調查', ''),
(null, null, 0, '08', '生理因素：例如要去睡覺、睡覺被吵醒、心情不好', ''),
(null, null, 0, '10', '受訪者主動表示不願意接受本機構訪問', ''),
(null, null, 0, '11', '誤認為推銷或另有目的', ''),
(null, null, 0, '12', '電話轉接至外縣市、手機或其他業務，受訪者不願或不便受訪', ''),
(null, null, 0, '98', '其他', ''),
(null, null, 0, '99', '原因不明', '');


-- --
---- 訪問語言設定(drop existing table first)
DROP TABLE IF EXISTS :schema.languages CASCADE;
-- Recreate the :schema.languages table
CREATE TABLE :schema.languages (
    id               serial PRIMARY KEY,
    project_id       integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id integer,
    qre_version      smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    language_cid     varchar(8) NOT NULL,
    description      varchar(500) NOT NULL,
    notes            text,
    CONSTRAINT fk_languages_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_languages_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.languages IS '訪問語言「設定」表';

COMMENT ON COLUMN :schema.languages.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.languages.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.languages.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.languages.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.languages.language_cid     IS '語言代碼';
COMMENT ON COLUMN :schema.languages.description      IS '語言說明';
COMMENT ON COLUMN :schema.languages.notes            IS '備註';

COMMENT ON INDEX :schema.languages_pkey IS '訪問語言設定table的PK索引，由系統自動建立';

-- Insert data into :schema.languages
INSERT INTO :schema.languages (project_id, questionnaire_id, qre_version, language_cid, description, notes) VALUES
(null, null, 0, '01', '全用國語', ''),
(null, null, 0, '02', '全用閩南語', ''),
(null, null, 0, '03', '全用客家語', ''),
(null, null, 0, '04', '國語、閩南語混用', ''),
(null, null, 0, '05', '國語、客家語混用', ''),
(null, null, 0, '06', '閩南語、客家語混用', ''),
(null, null, 0, '98', '其他(如用其他語言、未接觸受訪者等)', '');


-- --
---- 約訪(drop existing table first)
DROP TABLE IF EXISTS :schema.appointments CASCADE;
-- Recreate the :schema.appointments table
CREATE TABLE :schema.appointments (
    id                    serial PRIMARY KEY,
    project_id            integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id      integer,
    qre_version           smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    result_id             integer NOT NULL,
    tel                   varchar(30) NOT NULL,
    type                  char(1) NOT NULL,
    is_sent_to_self       boolean NOT NULL,
    scheduled_at          timestamp with time zone NOT NULL,
    sent_at               timestamp with time zone NOT NULL DEFAULT now(),
    sender_id             varchar(12),
    sender_name           varchar(80),
    recipient_ids         varchar(12)[],
    reason_str            varchar(500) NOT NULL,
    nth_dial              smallint NOT NULL CHECK (nth_dial >= 1 AND nth_dial <= 500),
    nth_human_contact     smallint NOT NULL CHECK (nth_human_contact >= 1 AND nth_human_contact <= 500),
    show_sender           boolean NOT NULL DEFAULT true,
    CONSTRAINT fk_appointments_results
        FOREIGN KEY(result_id)
        REFERENCES :schema.results(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.appointments IS '約訪主表';

COMMENT ON COLUMN :schema.appointments.id                IS '系統自動累加的id';
COMMENT ON COLUMN :schema.appointments.result_id         IS '訪問結果id，為references `results` table的foreign key';
COMMENT ON COLUMN :schema.appointments.tel               IS '電話號碼';
COMMENT ON COLUMN :schema.appointments.type              IS '約訪方式';
COMMENT ON COLUMN :schema.appointments.is_sent_to_self   IS '是否為本人傳送';
COMMENT ON COLUMN :schema.appointments.scheduled_at      IS '約訪日期時間';
COMMENT ON COLUMN :schema.appointments.sent_at           IS '傳送日期時間';
COMMENT ON COLUMN :schema.appointments.sender_id         IS '傳送的訪員編號';
COMMENT ON COLUMN :schema.appointments.sender_name       IS '傳送的訪員姓名';
COMMENT ON COLUMN :schema.appointments.recipient_ids     IS '接收的諸訪員編號(可能不只一名)';
COMMENT ON COLUMN :schema.appointments.reason_str        IS '約訪原因說明';
COMMENT ON COLUMN :schema.appointments.nth_dial          IS '第幾次撥號(2表約訪後的第1撥，範圍1-500)';
COMMENT ON COLUMN :schema.appointments.nth_human_contact IS '第幾次接觸到「人」(範圍1-500)';
COMMENT ON COLUMN :schema.appointments.show_sender       IS '要不要顯示傳送訪員的資訊(預設TRUE)';

-- 建立appointments table的索引
DROP INDEX IF EXISTS idx_appointments_project_id;
CREATE INDEX idx_appointments_project_id       ON :schema.appointments(project_id);
DROP INDEX IF EXISTS idx_appointments_questionnaire_id;
CREATE INDEX idx_appointments_questionnaire_id ON :schema.appointments(questionnaire_id);
DROP INDEX IF EXISTS idx_appointments_qre_version;
CREATE INDEX idx_appointments_qre_version      ON :schema.appointments(qre_version);
DROP INDEX IF EXISTS idx_appointments_result_id;
CREATE INDEX idx_appointments_result_id        ON :schema.appointments(result_id);
DROP INDEX IF EXISTS idx_appointments_scheduled_at;
CREATE INDEX idx_appointments_scheduled_at     ON :schema.appointments(scheduled_at);
DROP INDEX IF EXISTS idx_appointments_type;
CREATE INDEX idx_appointments_type             ON :schema.appointments(type);
DROP INDEX IF EXISTS gin_appointments_recipient_ids;
CREATE INDEX gin_appointments_recipient_ids    ON :schema.appointments USING GIN (recipient_ids);
COMMENT ON INDEX :schema.idx_appointments_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_appointments_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_appointments_qre_version      IS '問卷版本索引';
COMMENT ON INDEX :schema.idx_appointments_result_id        IS '訪問結果id(FK)的索引';
COMMENT ON INDEX :schema.idx_appointments_scheduled_at     IS '約訪時間索引';
COMMENT ON INDEX :schema.idx_appointments_type             IS '約訪方式索引';
COMMENT ON INDEX :schema.gin_appointments_recipient_ids    IS '接收約訪的諸訪員索引';
COMMENT ON INDEX :schema.appointments_pkey                 IS '約訪主table的PK索引，由系統自動建立';


-- --
---- 約訪傳送方式設定(drop existing table first)
DROP TABLE IF EXISTS :schema.appt_types CASCADE;
-- Recreate the :schema.appt_types table
CREATE TABLE :schema.appt_types (
    id               serial PRIMARY KEY,
    project_id       integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id integer,
    qre_version      smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    appt_type_cid    char(2) NOT NULL,
    description      varchar(500) NOT NULL,
    is_enabled       boolean NOT NULL,
    is_default       boolean NOT NULL,
    notes            text,
    CONSTRAINT fk_appt_types_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_appt_types_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.appt_types IS '約訪傳送方式「設定」表';

COMMENT ON COLUMN :schema.appt_types.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.appt_types.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.appt_types.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.appt_types.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.appt_types.appt_type_cid    IS '約訪傳送方式代碼';
COMMENT ON COLUMN :schema.appt_types.description      IS '約訪傳送方式說明';
COMMENT ON COLUMN :schema.appt_types.is_enabled       IS '是否允許';
COMMENT ON COLUMN :schema.appt_types.is_default       IS '是否為預設值';
COMMENT ON COLUMN :schema.appt_types.notes            IS '備註';

CREATE UNIQUE INDEX idx_unique_default_appt_type ON :schema.appt_types(is_default) WHERE is_default = true;
COMMENT ON INDEX :schema.idx_unique_default_appt_type IS '約束整個table只有一筆資料的`is_default`欄位為TRUE的索引(unique partial index)';
COMMENT ON INDEX :schema.appt_types_pkey      IS '約訪傳送方式設定table的PK索引，由系統自動建立';

-- Insert data into :schema.appt_types
INSERT INTO :schema.appt_types (project_id, questionnaire_id, qre_version, appt_type_cid, description, is_enabled, is_default, notes) VALUES
(null, null, 0, '1', '只給本人(本人離線後，其他訪員亦無法取用)        ', false, false, ''),
(null, null, 0, '2', '本人優先(本人離線後，其他訪員可以取用)          ', true,  true,  ''),
(null, null, 0, '3', '任一訪員(包括本人)                              ', false, false, ''),
(null, null, 0, '4', '其他訪員(本人除外)                              ', false, false, ''),
(null, null, 0, '5', '指定訪員(僅限客語訪員及特殊樣本)                ', true,  false, ''),
(null, null, 0, '6', '指定代理(本人優先。離線後，指定的代理人可以取用)', false, false, '');


-- --
---- 指定或代理訪員(約訪或其他)設定(drop existing table first)
DROP TABLE IF EXISTS :schema.project_assigned_ints CASCADE;
-- Recreate the :schema.project_assigned_ints table
CREATE TABLE :schema.project_assigned_ints (
    id               serial PRIMARY KEY,
    project_id       integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id integer,
    qre_version      smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    interviewer_id   smallint NOT NULL,
    interviewer_cid  varchar(12) NOT NULL,
    role             varchar(50),
    assigned_at      timestamp with time zone NOT NULL DEFAULT now(),
    notes            text,
    CONSTRAINT fk_project_assigned_ints_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_project_assigned_ints_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_project_assigned_ints_interviewers
        FOREIGN KEY(interviewer_id)
        REFERENCES :schema.interviewers(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.project_assigned_ints IS '(主要但不限定是約訪)指定或代理訪員「設定」表';

COMMENT ON COLUMN :schema.project_assigned_ints.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.project_assigned_ints.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.project_assigned_ints.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.project_assigned_ints.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.project_assigned_ints.interviewer_id   IS '指定或代理的訪員id，為references `interviewers` table的foreign key';
COMMENT ON COLUMN :schema.project_assigned_ints.interviewer_cid  IS '指定或代理的「自訂訪員編號」';
COMMENT ON COLUMN :schema.project_assigned_ints.role             IS '角色';
COMMENT ON COLUMN :schema.project_assigned_ints.assigned_at      IS '建檔時間';
COMMENT ON COLUMN :schema.project_assigned_ints.notes            IS '指定或代理訪員的「使用者自訂」編號';

COMMENT ON INDEX :schema.project_assigned_ints_pkey IS '約訪指定或代理訪員設定table的PK索引，由系統自動建立';

-- Insert data into :schema.project_assigned_ints table
INSERT INTO :schema.project_assigned_ints (project_id, questionnaire_id, qre_version, interviewer_id, interviewer_cid, role, notes) VALUES
(null, null, 0, 4, '0004', '客語訪員', ''),
(null, null, 0, 15, '0015', '督導', '');


-- --
---- 約訪原因設定(drop existing table first)
DROP TABLE IF EXISTS :schema.appt_reasons CASCADE;
-- Recreate the :schema.appt_reasons table
CREATE TABLE :schema.appt_reasons (
    id               serial PRIMARY KEY,
    project_id       integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id integer,
    qre_version      smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    appt_reason_cid  varchar(8) NOT NULL,
    description      varchar(500) NOT NULL,
    notes            text,
    CONSTRAINT fk_appt_reasons_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_appt_reasons_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.appt_reasons IS '約訪原因「設定」表';

COMMENT ON COLUMN :schema.appt_reasons.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.appt_reasons.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.appt_reasons.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.appt_reasons.qre_version      IS '問卷版本';
COMMENT ON COLUMN :schema.appt_reasons.appt_reason_cid  IS '約訪原因代碼';
COMMENT ON COLUMN :schema.appt_reasons.description      IS '約訪原因說明';
COMMENT ON COLUMN :schema.appt_reasons.notes            IS '備註';

COMMENT ON INDEX :schema.appt_reasons_pkey IS '約訪原因設定table的PK索引，由系統自動建立';

-- Insert data into :schema.appt_reasons
INSERT INTO :schema.appt_reasons (project_id, questionnaire_id, qre_version, appt_reason_cid, description, notes) VALUES
(null, null, 0, '01', '忙碌', ''),
(null, null, 0, '02', '正在燒菜煮飯', ''),
(null, null, 0, '03', '正在用餐', ''),
(null, null, 0, '04', '有訪客', ''),
(null, null, 0, '05', '要外出', ''),
(null, null, 0, '06', '合格受訪者(例如大人)不在家', ''),
(null, null, 0, '07', '有插撥電話進來，或訪員插撥進入', ''),
(null, null, 0, '08', '不方便接電話(例如洗澡等)', ''),
(null, null, 0, '09', '指定受訪者不在家', ''),
(null, null, 0, '10', '轉接手機', ''),
(null, null, 0, '11', '住商合一，正在忙', ''),
(null, null, 0, '12', '須用客語溝通', ''),
(null, null, 0, '98', '其他', '');


-- --
---- 加權母體資料設定表(drop existing table first)
DROP TABLE IF EXISTS :schema.populations CASCADE;
-- Recreate the :schema.populations table
CREATE TABLE :schema.populations (
    id               serial PRIMARY KEY,
    project_id       integer,
    questionnaire_id integer,
    population_cid   varchar(8),
    population_desc  varchar(200),
    category_cid     varchar(8),
    category_desc    varchar(200),
    percent          DECIMAL(5, 2),
    CONSTRAINT fk_populations_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_populations_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.populations IS '加權母體資料設定表';

COMMENT ON COLUMN :schema.populations.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.populations.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.populations.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.populations.population_cid   IS '母體變數代碼';
COMMENT ON COLUMN :schema.populations.population_desc  IS '母體變數說明';
COMMENT ON COLUMN :schema.populations.category_cid     IS '母體變數的層別代碼';
COMMENT ON COLUMN :schema.populations.category_desc    IS '母體變數的層別說明';
COMMENT ON COLUMN :schema.populations.percent          IS '母體百分比';

-- 建立populations table的索引
DROP INDEX IF EXISTS idx_populations_project_id;
CREATE INDEX idx_populations_project_id       ON :schema.populations(project_id);
DROP INDEX IF EXISTS idx_populations_questionnaire_id;
CREATE INDEX idx_populations_questionnaire_id ON :schema.populations(questionnaire_id);
COMMENT ON INDEX :schema.idx_populations_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_populations_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.populations_pkey                 IS '母體資料設定table的PK索引，由系統自動建立';

-- Insert data into :schema.populations
INSERT INTO :schema.populations (project_id, questionnaire_id, population_cid, population_desc, category_cid, category_desc, percent) VALUES
(null, null, 1, '性別',     1, '男',       49.31),
(null, null, 1, '性別',     2, '女',       50.69),
(null, null, 2, '年齡',     1, '20-29歲',  16.97),
(null, null, 2, '年齡',     2, '30-39歲',  20.88),
(null, null, 2, '年齡',     3, '40-49歲',  19.25),
(null, null, 2, '年齡',     4, '50-59歲',  19.19),
(null, null, 2, '年齡',     5, '60歲以上', 23.71),
(null, null, 3, '教育程度', 1, '小學以下', 14.84),
(null, null, 3, '教育程度', 2, '初/國中',  12.84),
(null, null, 3, '教育程度', 3, '高中/職',  28.20),
(null, null, 3, '教育程度', 4, '專科',     12.19),
(null, null, 3, '教育程度', 5, '大學以上', 31.93),
(null, null, 4, '六都',     1, '台北市',   15.38),
(null, null, 4, '六都',     2, '新北市',   24.77),
(null, null, 4, '六都',     3, '桃園市',   14.23),
(null, null, 4, '六都',     4, '台中市',   17.46),
(null, null, 4, '六都',     5, '台南市',   11.40),
(null, null, 4, '六都',     6, '高雄市',   16.77),
(null, null, 5, '縣市',     1, '新北市',   17.26),
(null, null, 5, '縣市',     2, '台北市',   10.72),
(null, null, 5, '縣市',     3, '桃園市',    9.91),
(null, null, 5, '縣市',     4, '台中市',   12.17),
(null, null, 5, '縣市',     5, '台南市',    7.94),
(null, null, 5, '縣市',     6, '高雄市',   11.69),
(null, null, 5, '縣市',     7, '宜蘭縣',    1.92),
(null, null, 5, '縣市',     8, '新竹縣',    2.52),
(null, null, 5, '縣市',     9, '苗栗縣',    2.28),
(null, null, 5, '縣市',    10, '彰化縣',    5.28),
(null, null, 5, '縣市',    11, '南投縣',    2.03),
(null, null, 5, '縣市',    12, '雲林縣',    2.82),
(null, null, 5, '縣市',    13, '嘉義縣',    2.06),
(null, null, 5, '縣市',    14, '屏東縣',    3.39),
(null, null, 5, '縣市',    15, '台東縣',    0.90),
(null, null, 5, '縣市',    16, '花蓮縣',    1.35),
(null, null, 5, '縣市',    17, '澎湖縣',    0.46),
(null, null, 5, '縣市',    18, '基隆市',    1.55),
(null, null, 5, '縣市',    19, '新竹市',    1.95),
(null, null, 5, '縣市',    20, '嘉義市',    1.12),
(null, null, 5, '縣市',    21, '金門縣',    0.62),
(null, null, 5, '縣市',    22, '連江縣',    0.06);


-- --
---- 加權變數資料設定表(drop existing table first)
DROP TABLE IF EXISTS :schema.wgt_vars CASCADE;
-- Recreate the :schema.wgt_vars table
CREATE TABLE :schema.wgt_vars (
    id                serial PRIMARY KEY,
    project_id        integer,
    questionnaire_id  integer,
    population_cid    varchar(8) NOT NULL,
    description       varchar(200),
    user_qst_cid      smallint,
    significant_level DECIMAL(5, 2) NOT NULL,
    CONSTRAINT fk_wgt_vars_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_wgt_vars_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.wgt_vars IS '加權變數資料設定表';

COMMENT ON COLUMN :schema.wgt_vars.id                IS '系統自動累加的id';
COMMENT ON COLUMN :schema.wgt_vars.project_id        IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.wgt_vars.questionnaire_id  IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.wgt_vars.population_cid    IS '母體變數代碼';
COMMENT ON COLUMN :schema.wgt_vars.description       IS '變數說明';
COMMENT ON COLUMN :schema.wgt_vars.user_qst_cid      IS '問卷的「使用者」題號';
COMMENT ON COLUMN :schema.wgt_vars.significant_level IS '顯著水準';

-- 建立wgt_vars table的索引
DROP INDEX IF EXISTS idx_wgt_vars_project_id;
CREATE INDEX idx_wgt_vars_project_id       ON :schema.wgt_vars(project_id);
DROP INDEX IF EXISTS idx_wgt_vars_questionnaire_id;
CREATE INDEX idx_wgt_vars_questionnaire_id ON :schema.wgt_vars(questionnaire_id);
DROP INDEX IF EXISTS idx_wgt_vars_population_cid;
CREATE INDEX idx_wgt_vars_population_cid   ON :schema.wgt_vars(population_cid);
COMMENT ON INDEX :schema.idx_wgt_vars_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_wgt_vars_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_wgt_vars_population_cid   IS '母體變數代碼索引';
COMMENT ON INDEX :schema.wgt_vars_pkey                 IS '加權變數資料設定table的PK索引，由系統自動建立';

-- Insert data into :schema.wgt_vars
INSERT INTO :schema.wgt_vars (project_id, questionnaire_id, population_cid, description, user_qst_cid, significant_level) VALUES
(null, null, 1, '性別',    -1,  0.95),
(null, null, 2, '年齡',    20,  0.95),
(null, null, 3, '教育',    21,  0.95),
(null, null, 4, '六都',    22,  0.95);


-- --
---- 重撥(drop existing table first)
DROP TABLE IF EXISTS :schema.callbacks CASCADE;
-- Recreate the :schema.callbacks table
CREATE TABLE :schema.callbacks (
    id               serial PRIMARY KEY,
    project_id       integer NOT NULL,
    questionnaire_id integer NOT NULL,
    quota_cid        varchar(30) NOT NULL,
    outcome_cid      varchar(8) NOT NULL,
    tel              varchar(30) NOT NULL,
    interviewer_id   varchar(30),   -- why?
    scheduled_at     timestamp with time zone,
    last_called_at   timestamp with time zone,
    nth_dial         smallint NOT NULL CHECK (nth_dial >= 1 AND nth_dial <= 500),
    sample_info      jsonb,
    CONSTRAINT fk_callbacks_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_callbacks_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
);
COMMENT ON TABLE :schema.callbacks IS '待重撥電話號碼表';

COMMENT ON COLUMN :schema.callbacks.id               IS '系統自動累加的id';
COMMENT ON COLUMN :schema.callbacks.project_id       IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.callbacks.questionnaire_id IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.callbacks.quota_cid        IS '樣本配額層別代碼';
COMMENT ON COLUMN :schema.callbacks.outcome_cid      IS '上通撥號結果代碼';
COMMENT ON COLUMN :schema.callbacks.tel              IS '電話號碼';
COMMENT ON COLUMN :schema.callbacks.interviewer_id   IS '訪員編號(暫無作用)';  -- why?
COMMENT ON COLUMN :schema.callbacks.scheduled_at     IS '預定重撥日期時間';
COMMENT ON COLUMN :schema.callbacks.last_called_at   IS '上通日期時間';
COMMENT ON COLUMN :schema.callbacks.nth_dial         IS '第幾次撥號(2表第1次重撥，範圍1-500)';
COMMENT ON COLUMN :schema.callbacks.sample_info      IS '樣本資訊';

DROP INDEX IF EXISTS idx_callbacks_project_id;
CREATE INDEX idx_callbacks_project_id       ON :schema.callbacks(project_id);
DROP INDEX IF EXISTS idx_callbacks_questionnaire_id;
CREATE INDEX idx_callbacks_questionnaire_id ON :schema.callbacks(questionnaire_id);
DROP INDEX IF EXISTS idx_callbacks_outcome_cid;
CREATE INDEX idx_callbacks_outcome_cid      ON :schema.callbacks(outcome_cid);
DROP INDEX IF EXISTS idx_callbacks_scheduled_at;
CREATE INDEX idx_callbacks_scheduled_at     ON :schema.callbacks(scheduled_at);
COMMENT ON INDEX :schema.idx_callbacks_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_callbacks_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_callbacks_outcome_cid      IS '上通撥號結果代碼索引';
COMMENT ON INDEX :schema.idx_callbacks_scheduled_at     IS '預定重撥日期時間索引';
COMMENT ON INDEX :schema.callbacks_pkey                 IS '重撥table的PK索引，由系統自動建立';


-- --
---- 戶內抽樣表(drop existing table first)
DROP TABLE IF EXISTS :schema.whss CASCADE;
-- Recreate the :schema.whss table
CREATE TABLE :schema.whss (
    id                    serial PRIMARY KEY,
    project_id            integer,  -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    questionnaire_id      integer,
    qre_version           smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    num_eligibles         smallint CHECK (num_eligibles >= 0 AND num_eligibles <= 99),
    num_males             smallint CHECK (num_males >= 0 AND num_males <= 99),
    weight                DECIMAL(4, 1) CHECK (weight >= 0.0 AND weight <= 100.0),
    start_tel             char(2) CHECK (start_tel SIMILAR TO '([0-9][0-9])'),
    end_tel               char(2) CHECK (end_tel SIMILAR TO '([0-9][0-9])'),
    priority              smallint CHECK (priority >= 1 AND priority <= 9),
    designated_respondent varchar(100),
    notes                 text,
    CONSTRAINT fk_whss_projects
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_whss_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE,
    CHECK (start_tel < end_tel)
);
COMMENT ON TABLE :schema.whss IS '戶內抽樣(whs=within_household_selection)設定表';

COMMENT ON COLUMN :schema.whss.id                    IS '系統自動累加的id';
COMMENT ON COLUMN :schema.whss.project_id            IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.whss.questionnaire_id      IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.whss.qre_version           IS '問卷版本';
COMMENT ON COLUMN :schema.whss.num_eligibles         IS '合格者人數';
COMMENT ON COLUMN :schema.whss.num_males             IS '男性人數';
COMMENT ON COLUMN :schema.whss.weight                IS '權數';
COMMENT ON COLUMN :schema.whss.start_tel             IS '電話尾數起始值';
COMMENT ON COLUMN :schema.whss.end_tel               IS '電話尾數結束值';
COMMENT ON COLUMN :schema.whss.priority              IS '優先順序';
COMMENT ON COLUMN :schema.whss.designated_respondent IS '指定受訪者';
COMMENT ON COLUMN :schema.whss.notes                 IS '備註';

DROP INDEX IF EXISTS idx_whss_project_id;
CREATE INDEX idx_whss_project_id       ON :schema.whss(project_id);
DROP INDEX IF EXISTS idx_whss_questionnaire_id;
CREATE INDEX idx_whss_questionnaire_id ON :schema.whss(questionnaire_id);
DROP INDEX IF EXISTS idx_whss_qre_version;
CREATE INDEX idx_whss_qre_version      ON :schema.whss(qre_version);
COMMENT ON INDEX :schema.idx_whss_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_whss_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_whss_qre_version      IS '問卷版本索引';
COMMENT ON INDEX :schema.whss_pkey                 IS '戶內抽樣table的PK索引，由系統自動建立';

-- Insert data into :schema.whss
INSERT INTO :schema.whss (project_id, questionnaire_id, qre_version, num_eligibles, num_males, weight, start_tel, end_tel, priority, designated_respondent, notes) VALUES
(null, null, 0,  1,  0, 100.0, '00', '99', 1, '唯一合格女性', ''),
(null, null, 0,  1,  0, 100.0, '00', '99', 2, '無', ''),
(null, null, 0,  1,  1, 100.0, '00', '99', 1, '唯一合格男性', ''),
(null, null, 0,  1,  1, 100.0, '00', '99', 2, '無', ''),
(null, null, 0,  2,  0, 100.0, '00', '99', 1, '較年輕女性',  ''),
(null, null, 0,  2,  0, 100.0, '00', '99', 2, '較年長女性', ''),
(null, null, 0,  2,  1,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  2,  1,  50.0, '00', '49', 2, '唯一合格男性', ''),
(null, null, 0,  2,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  2,  1,  50.0, '50', '99', 2, '唯一合格女性', ''),
(null, null, 0,  2,  2, 100.0, '00', '99', 1, '較年輕男性',  ''),
(null, null, 0,  2,  2, 100.0, '00', '99', 2, '較年長男性', ''),
(null, null, 0,  3,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  3,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  3,  1,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  3,  1,  50.0, '00', '49', 2, '唯一合格男性', ''),
(null, null, 0,  3,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  3,  1,  50.0, '50', '99', 2, '較年輕女性', ''),
(null, null, 0,  3,  2,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  3,  2,  50.0, '00', '49', 2, '較年輕男性', ''),
(null, null, 0,  3,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  3,  2,  50.0, '50', '99', 2, '唯一合格女性', ''),
(null, null, 0,  3,  3, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  3,  3, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  4,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  4,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  4,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  4,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  4,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  4,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  4,  2,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  4,  2,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  4,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  4,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  4,  3,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  4,  3,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  4,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  4,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  4,  4, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  4,  4, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  5,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  5,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  5,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  5,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  5,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  5,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  5,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  5,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  5,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  5,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  5,  3,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  5,  3,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  5,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  5,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  5,  4,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  5,  4,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  5,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  5,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  5,  5, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  5,  5, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  6,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  6,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  6,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  6,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  6,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  6,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  6,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  6,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  6,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  6,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  6,  3,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  6,  3,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  6,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  6,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  6,  4,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  6,  4,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  6,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  6,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  6,  5,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  6,  5,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  6,  5,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  6,  5,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  6,  6, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  6,  6, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  7,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  7,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  7,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  7,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  7,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  7,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  7,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  7,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  7,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  7,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  7,  3,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  7,  3,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  7,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  7,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  7,  4,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  7,  4,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  7,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  7,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  7,  5,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  7,  5,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  7,  5,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  7,  5,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  7,  6,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  7,  6,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  7,  6,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  7,  6,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  7,  7, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  7,  7, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  8,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  8,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  8,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  8,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  8,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  8,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  8,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  8,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  8,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  8,  3,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  8,  3,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  8,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  4,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  8,  4,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  8,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  5,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  8,  5,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  8,  5,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  5,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  6,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  8,  6,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  8,  6,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  6,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  7,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  8,  7,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  8,  7,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  7,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  8,  8, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  8,  8, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0,  9,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0,  9,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0,  9,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0,  9,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0,  9,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0,  9,  3,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  3,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  4,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  4,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  5,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  5,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  5,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  5,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  6,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0,  9,  6,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0,  9,  6,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  6,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  7,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0,  9,  7,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0,  9,  7,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  7,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  8,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0,  9,  8,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0,  9,  8,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  8,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0,  9,  9, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0,  9,  9, 100.0, '00', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  0, 100.0, '00', '99', 1, '最年輕女性',  ''),
(null, null, 0, 10,  0, 100.0, '00', '99', 2, '最年長女性', ''),
(null, null, 0, 10,  1,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  1,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  1,  50.0, '50', '99', 1, '唯一合格男性', ''),
(null, null, 0, 10,  1,  50.0, '50', '99', 2, '最年輕女性', ''),
(null, null, 0, 10,  2,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  2,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  2,  50.0, '50', '99', 1, '較年輕男性',  ''),
(null, null, 0, 10,  2,  50.0, '50', '99', 2, '較年長男性', ''),
(null, null, 0, 10,  3,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  3,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  3,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  3,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  4,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  4,  50.0, '00', '49', 2, '最年長男性', ''),
(null, null, 0, 10,  4,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  4,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  5,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  5,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  5,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  5,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  6,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  6,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  6,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  6,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  7,  50.0, '00', '49', 1, '最年輕女性',  ''),
(null, null, 0, 10,  7,  50.0, '00', '49', 2, '最年長女性', ''),
(null, null, 0, 10,  7,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  7,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  8,  50.0, '00', '49', 1, '較年輕女性',  ''),
(null, null, 0, 10,  8,  50.0, '00', '49', 2, '較年長女性', ''),
(null, null, 0, 10,  8,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  8,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10,  9,  50.0, '00', '49', 1, '唯一合格女性', ''),
(null, null, 0, 10,  9,  50.0, '00', '49', 2, '最年輕男性', ''),
(null, null, 0, 10,  9,  50.0, '50', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10,  9,  50.0, '50', '99', 2, '最年長男性', ''),
(null, null, 0, 10, 10, 100.0, '00', '99', 1, '最年輕男性',  ''),
(null, null, 0, 10, 10, 100.0, '00', '99', 2, '最年長男性', '');


-- --
---- 訪員班別表(drop existing table first)
DROP TABLE IF EXISTS :schema.shifts CASCADE;
-- Recreate the :schema.shifts table
CREATE TABLE :schema.shifts (
    id          smallserial PRIMARY KEY,
    shift_cid   varchar(8) NOT NULL,
    description varchar(100) NOT NULL,
    runs_from   char(5) NOT NULL,
    runs_to     char(5) NOT NULL,
    notes       text
);
COMMENT ON TABLE :schema.shifts IS '訪員班別表';

COMMENT ON COLUMN :schema.shifts.id          IS '系統自動累加的id';
COMMENT ON COLUMN :schema.shifts.shift_cid   IS '班別代碼';
COMMENT ON COLUMN :schema.shifts.description IS '班別內容說明';
COMMENT ON COLUMN :schema.shifts.runs_from   IS '到班時間';
COMMENT ON COLUMN :schema.shifts.runs_to     IS '下班時間';
COMMENT ON COLUMN :schema.shifts.notes       IS '備註';

COMMENT ON INDEX :schema.shifts_pkey IS '訪員班別table的PK索引，由系統自動建立';

-- Insert data into :schema.shifts
INSERT INTO :schema.shifts (shift_cid, description, runs_from, runs_to, notes) VALUES
('1', '上午班', '09:00', '12:30', ''),
('2', '下午班', '13:30', '17:00', ''),
('3', '晚上班', '18:00', '21:30', ''),
('4', '全日班', '09:00', '21:30', '');


-- --
---- 訪問室座位表(drop existing table first)
DROP TABLE IF EXISTS :schema.mac_seats CASCADE;
-- Recreate the :schema.mac_seats table
CREATE TABLE :schema.mac_seats (
    id          smallserial PRIMARY KEY,
    mac_address char(12),
    room_cid    varchar(8),
    seat_cid    varchar(8),
    speaker     char(1) CHECK (speaker = '1' OR speaker = '2' OR speaker = '3'),
    notes       text
);
COMMENT ON TABLE :schema.mac_seats IS '訪問室座位表';

COMMENT ON COLUMN :schema.mac_seats.id          IS '系統自動累加的id';
COMMENT ON COLUMN :schema.mac_seats.mac_address IS 'MAC address';
COMMENT ON COLUMN :schema.mac_seats.room_cid    IS '訪問室編號';
COMMENT ON COLUMN :schema.mac_seats.seat_cid    IS '座號';
COMMENT ON COLUMN :schema.mac_seats.speaker     IS '蜂鳴器音量("1": 小  "2": 中  "3": 大。暫無作用)';
COMMENT ON COLUMN :schema.mac_seats.notes       IS '備註';

COMMENT ON INDEX :schema.mac_seats_pkey IS '訪問室座位table的PK索引，由系統自動建立';

-- Insert data into :schema.mac_seats
INSERT INTO :schema.mac_seats (mac_address, room_cid, seat_cid, speaker, notes) VALUES
('19fe64fcbaea', '', '01', '1', ''),
('8b81f376f956', '', '02', '1', ''),
('de4ddf3fbf41', '', '03', '1', ''),
('b81e66a61e43', '', '04', '1', ''),
('02b4ba5f6527', '', '05', '1', ''),
('bf83991bc0a2', '', '06', '1', ''),
('c9679be41088', '', '07', '1', ''),
('16eb777fba4a', '', '08', '3', ''),
('23d80ffb6497', '', '09', '1', ''),
('df90609f81b9', '', '10', '1', ''),
('6a416364c90c', '', '11', '1', ''),
('fd4c991f9007', '', '12', '2', ''),
('4fde65bc6274', '', '13', '2', ''),
('e6a9b7205c57', '', '14', '2', ''),
('ab2314ca3cab', '', '15', '2', ''),
('30b3f2f84da6', '', '16', '2', ''),
('d528a0cee36d', '', '17', '2', ''),
('a7512e114b04', '', '18', '1', ''),
('576c1d3c6839', '', '19', '1', ''),
('c3c8e80946a0', '', '20', '1', ''),
('b094f8827365', '', '21', '1', ''),
('692fad1d2cb6', '', '22', '3', ''),
('f3c05a4a8be3', '', '23', '3', ''),
('c90cf5e9f513', '', '24', '3', ''),
('d67b264b9741', '', '25', '2', ''),
('f0520f1d1d48', '', '26', '2', ''),
('e07b42fc72fb', '', '27', '2', ''),
('d1546be777ba', '', '28', '2', ''),
('591da157bb00', '', '29', '1', ''),
('c8723ecc82a6', '', '30', '1', ''),
('7d41c225f6bb', '', '31', '1', ''),
('1315e537db97', '', '32', '1', ''),
('c6c09fee1c78', '', '33', '3', ''),
('75ee2feb248e', '', '34', '3', ''),
('25c2cf30f99f', '', '35', '3', ''),
('67c4cd74a157', '', '36', '3', ''),
('01d9cc736390', '', '37', '3', ''),
('70e412e30fbe', '', '38', '3', ''),
('f7e6f79c6b95', '', '39', '2', ''),
('aadc682f5c91', '', '40', '2', '');


-- --
---- 環境設定表(drop existing table first)
DROP TABLE IF EXISTS :schema.configs CASCADE;
-- Recreate the :schema.configs table
CREATE TABLE :schema.configs (
    id                    serial PRIMARY KEY,
    project_id            integer,    -- 所有屬於「設定類」的tables，其project_id, questionnaire_id等都不可以為NOT null，因為null是用來代表「公共設定」。
    project_cid           varchar(50),
    questionnaire_id      integer,
    qre_version           smallint CHECK (qre_version >= -1 AND qre_version <= 9999),
    cover_image           varchar(300),
    logo_image            varchar(300),
    login_level           smallint NOT NULL DEFAULT 2 CHECK (login_level >= 0 AND login_level <= 2),
    survey_method         char(1) DEFAULT 'W' CHECK (survey_method IN ('T', 'W', 'E', 'P', 'H', 'S')),
    tel_area_code         char(4) NOT NULL,
    tel_format            varchar(30),
    tel_pseudo            varchar(30),
    tel_min_len           smallint NOT NULL DEFAULT 1,
    tel_external_prefix   char(4) NOT NULL,
    tel_prefix_scope      char(1),
    tel_filter            char(1),
    black_collect_me      boolean NOT NULL DEFAULT true,
    black_sampling_type   char(1) NOT NULL DEFAULT 'X' CHECK (black_sampling_type IN ('X', 'x', 'M', 'm', 'G', 'g')),
    black_marking_type    char(1) NOT NULL DEFAULT 'X' CHECK (black_marking_type IN ('X', 'M', 'G')),
    sam_completions_exp   integer NOT NULL DEFAULT 1068 CHECK (sam_completions_exp >= 0),
    sam_expanding_times   smallint NOT NULL DEFAULT 12 CHECK (sam_expanding_times >= 0),
    sam_rdd_digits        smallint NOT NULL DEFAULT 2 CHECK (sam_rdd_digits >= 1 AND sam_rdd_digits <= 10),
    sam_go_into_towns     boolean NOT NULL DEFAULT true,
    appt_max_attempts     smallint NOT NULL DEFAULT 10 CHECK (appt_max_attempts >= 1 AND appt_max_attempts <= 200),
    appt_valid_on         date,
    appt_max_days         smallint DEFAULT 10 CHECK (appt_max_days >= 0 AND appt_max_days <= 1096),
    appt_logs             smallint DEFAULT 999 CHECK (appt_logs >= 0 AND appt_logs <= 200),
    appt_show_sender      boolean NOT NULL DEFAULT true,
    appt_is_cross_project char(1) DEFAULT 'P',
    appt_prompt_mins      smallint NOT NULL DEFAULT 3,
    cb_shortest_mins      smallint NOT NULL DEFAULT 60,
    cb_longest_mins       smallint NOT NULL DEFAULT 180,
    cb_max_attempts       smallint NOT NULL DEFAULT 5,
    cb_delivers_from      char(5) NOT NULL DEFAULT '19:30',
    cb_percent            DECIMAL(5, 2) NOT NULL DEFAULT 33.33,
    wgt_max_iterations    smallint NOT NULL DEFAULT 20 CHECK (wgt_max_iterations >= 1 AND wgt_max_iterations <= 500),
    wgt_cof_for_missing   smallint NOT NULL DEFAULT 0 CHECK (wgt_cof_for_missing = 0 OR wgt_cof_for_missing = 1),
    qre_sys_missing       char(1) NOT NULL DEFAULT '9',
    qre_allow_missing     boolean DEFAULT false,
    qre_is_whs_used       boolean NOT NULL DEFAULT false,
    qre_browse_mode       char(1) NOT NULL DEFAULT 'E',
    qre_show_tel          boolean NOT NULL DEFAULT true,
    qre_option_len        smallint NOT NULL DEFAULT 1,
    qre_rnd_option_thrs   smallint DEFAULT 4,
    qre_auto_fill         boolean DEFAULT false,
    qre_fore_color        char(7) NOT NULL DEFAULT '#FF4500',
    qre_back_color        char(7) NOT NULL DEFAULT '#F5F5F5',
    qre_info_color        char(7),
    qre_need_check        boolean DEFAULT false,
    qre_is_locked         boolean NOT NULL DEFAULT false,
    qre_is_readonly       boolean NOT NULL DEFAULT false,
    web_allow_refill      boolean DEFAULT false,
    oth_input_method      varchar(20) DEFAULT '注音',
    oth_duty_table_title  varchar(100) DEFAULT '訪員登班表',
    notes                 text,
    CONSTRAINT fk_configs_projects_id
        FOREIGN KEY(project_id)
        REFERENCES :schema.projects(id)
        ON DELETE CASCADE,
    CONSTRAINT fk_configs_projects_cid
        FOREIGN KEY(project_cid)
        REFERENCES :schema.projects(project_cid)
        ON DELETE CASCADE
        ON UPDATE CASCADE,
    CONSTRAINT fk_configs_questionnaires
        FOREIGN KEY(questionnaire_id)
        REFERENCES :schema.questionnaires(id)
        ON DELETE CASCADE
 );

COMMENT ON TABLE :schema.configs IS '環境設定表';

COMMENT ON COLUMN :schema.configs.id                    IS '系統自動累加的id';
COMMENT ON COLUMN :schema.configs.project_id            IS '所屬專案id，為references `projects` table的foreign key';
COMMENT ON COLUMN :schema.configs.project_cid           IS '所屬專案的自訂編號';
COMMENT ON COLUMN :schema.configs.questionnaire_id      IS '所屬問卷id，為references `questionnaires` table的foreign key';
COMMENT ON COLUMN :schema.configs.qre_version           IS '問卷版本';
COMMENT ON COLUMN :schema.configs.cover_image           IS '封面圖檔『存放路徑』';
COMMENT ON COLUMN :schema.configs.logo_image            IS '問卷左上角logo圖檔『存放路徑』';
COMMENT ON COLUMN :schema.configs.login_level           IS '問卷開放程度，0: 公開(不用登入)  1: 不公開(不用登入)  2: 私人(要登入)';
COMMENT ON COLUMN :schema.configs.survey_method         IS '方法：調查所用方法："T": 電話訪問  "W": 網路調查  "E": email調查  "P": 郵寄問卷  "H": 到府訪問  "S": 街頭訪問';
COMMENT ON COLUMN :schema.configs.tel_area_code         IS '電話：本地區域碼(自動撥號用)。如無區域碼或不使用自動撥號，本欄請設為空字串或空白字串';
COMMENT ON COLUMN :schema.configs.tel_format            IS '電話：門號格式';
COMMENT ON COLUMN :schema.configs.tel_pseudo            IS '電話：虛擬門號';
COMMENT ON COLUMN :schema.configs.tel_min_len           IS '電話：門號最短長度';
COMMENT ON COLUMN :schema.configs.tel_external_prefix   IS '電話：分機外線碼(多為"0"或"9")或固網業者的前綴碼，';
COMMENT ON COLUMN :schema.configs.tel_prefix_scope      IS '電話：前綴碼適用範圍：1: 所有地區  2: 僅區域碼以外地區';
COMMENT ON COLUMN :schema.configs.tel_filter            IS '電話：過濾(??)';
COMMENT ON COLUMN :schema.configs.black_collect_me      IS '黑名單：訪員程式是否要收集電話黑名單';
COMMENT ON COLUMN :schema.configs.black_sampling_type   IS '黑名單：抽樣時是否排除黑名單："X":排除  "x":詢間(預設排除)  "M":註記  "m":詢問(預設註記)  "G":放行  "g":詢問(預設放行)';
COMMENT ON COLUMN :schema.configs.black_marking_type    IS '黑名單：抽樣時如選擇「註記」黑名單，訪員程式在取用黑名單門號時的處理方式："X":不撥出亦不記錄   "M":不撥出但記錄   "G":正常撥出';
COMMENT ON COLUMN :schema.configs.sam_completions_exp   IS '樣本：預設完成數(台灣民調界常定為1068)';
COMMENT ON COLUMN :schema.configs.sam_expanding_times   IS '樣本：要從電話資料庫中抽出預定完成數「多少倍」的樣本';
COMMENT ON COLUMN :schema.configs.sam_rdd_digits        IS '樣本：RDD位數';
COMMENT ON COLUMN :schema.configs.sam_go_into_towns     IS '樣本：抽取縣市時，配額要不要細分到鄉鎮市區';
COMMENT ON COLUMN :schema.configs.appt_max_attempts     IS '約訪：最多再撥幾次';
COMMENT ON COLUMN :schema.configs.appt_valid_on         IS '約訪：預約的截止日期';
COMMENT ON COLUMN :schema.configs.appt_max_days         IS '約訪：往後最多可預約幾天。0表只能預約當天，1為可約隔天，7則意味最多可約一個星期...(範圍0-1096)';
COMMENT ON COLUMN :schema.configs.appt_logs             IS '約訪：預約紀錄顯示次數';
COMMENT ON COLUMN :schema.configs.appt_show_sender      IS '約訪：是否顯示傳送者資訊(預設顯示)';
COMMENT ON COLUMN :schema.configs.appt_is_cross_project IS '約訪：是否允許跨專案約訪："P": 禁止  "L": 允許(預設本專案)  "O": 允許(預設其他專案)';
COMMENT ON COLUMN :schema.configs.appt_prompt_mins      IS '約訪：約訪時間到之前的幾分鐘提示訪員';
COMMENT ON COLUMN :schema.configs.cb_shortest_mins      IS '重撥：最快在多少分鐘後重撥';
COMMENT ON COLUMN :schema.configs.cb_longest_mins       IS '重撥：最慢在多少分鐘後重撥';
COMMENT ON COLUMN :schema.configs.cb_max_attempts       IS '重撥：最多重撥次數(如設為5表最多重撥5次，連同第一次即最多撥出6次)';
COMMENT ON COLUMN :schema.configs.cb_delivers_from      IS '重撥：每天從甚麼時間起提供重撥門號';
COMMENT ON COLUMN :schema.configs.cb_percent            IS '重撥：占全部撥出中門號的最高百分比(目的是錯開重撥門號，以免同一時間太多重撥)';
COMMENT ON COLUMN :schema.configs.wgt_max_iterations    IS '加權：預設輪數，範圍1-500';
COMMENT ON COLUMN :schema.configs.wgt_cof_for_missing   IS '加權：該筆有missing資料時以甚麼權值填補，目前只有0和1兩個選擇';
COMMENT ON COLUMN :schema.configs.qre_sys_missing       IS '問卷：system missing值。如設為"9"實際上是"9", "99", "999", ...等(視每一題的單一答案長度而定))';
COMMENT ON COLUMN :schema.configs.qre_allow_missing     IS '問卷：訪員程式是否可以輸內system missing值';
COMMENT ON COLUMN :schema.configs.qre_is_whs_used       IS '問卷：是否戶內抽樣';
COMMENT ON COLUMN :schema.configs.qre_browse_mode       IS '問卷：瀏覽模式："E"輕鬆瀏覽  "T":效果測試';
COMMENT ON COLUMN :schema.configs.qre_show_tel          IS '問卷：訪員畫面是否顯示撥出的電話門號';
COMMENT ON COLUMN :schema.configs.qre_option_len        IS '問卷：預設選項長度';
COMMENT ON COLUMN :schema.configs.qre_rnd_option_thrs   IS '問卷：隨機選項加註編號的門檻數';
COMMENT ON COLUMN :schema.configs.qre_auto_fill         IS '問卷：答案是否自動填滿(暫不使用)';
COMMENT ON COLUMN :schema.configs.qre_fore_color        IS '問卷：前景顏色';
COMMENT ON COLUMN :schema.configs.qre_back_color        IS '問卷：背景顏色';
COMMENT ON COLUMN :schema.configs.qre_info_color        IS '問卷：(暫不使用)';
COMMENT ON COLUMN :schema.configs.qre_need_check        IS '問卷：答案輸入後是否須確認??(暫不使用)';
COMMENT ON COLUMN :schema.configs.qre_is_locked         IS '問卷：是否上鎖';
COMMENT ON COLUMN :schema.configs.qre_is_readonly       IS '問卷：是否唯讀(封版)';
COMMENT ON COLUMN :schema.configs.web_allow_refill      IS '網路：是否允許受訪者「續填」(非重複填寫)問卷';
COMMENT ON COLUMN :schema.configs.oth_input_method      IS '其他：預設輸入法';
COMMENT ON COLUMN :schema.configs.oth_duty_table_title  IS '其他：登班表標題';
COMMENT ON COLUMN :schema.configs.notes                 IS '備註';

DROP INDEX IF EXISTS idx_configs_project_id;
CREATE INDEX idx_configs_project_id       ON :schema.configs(project_id);
DROP INDEX IF EXISTS idx_configs_project_cid;
CREATE INDEX idx_configs_project_cid      ON :schema.configs(project_cid);
DROP INDEX IF EXISTS idx_configs_questionnaire_id;
CREATE INDEX idx_configs_questionnaire_id ON :schema.configs(questionnaire_id);
DROP INDEX IF EXISTS idx_configs_qre_version;
CREATE INDEX idx_configs_qre_version      ON :schema.configs(qre_version);
COMMENT ON INDEX :schema.idx_configs_project_id       IS '專案編號索引';
COMMENT ON INDEX :schema.idx_configs_project_cid      IS '自訂專案編號索引';
COMMENT ON INDEX :schema.idx_configs_questionnaire_id IS '問卷編號索引';
COMMENT ON INDEX :schema.idx_configs_qre_version      IS '問卷版本索引';
COMMENT ON INDEX :schema.configs_pkey                 IS '環境設定table的PK索引，由系統自動建立';

-- Insert data into :schema.configs
INSERT INTO :schema.configs (project_id, project_cid, questionnaire_id, qre_version, cover_image, logo_image, login_level, survey_method, tel_area_code, tel_format, tel_pseudo, tel_min_len, tel_external_prefix, tel_prefix_scope, tel_filter, black_collect_me, black_sampling_type, black_marking_type, sam_completions_exp, sam_expanding_times, sam_rdd_digits, sam_go_into_towns, appt_max_attempts, appt_valid_on, appt_max_days, appt_logs, appt_show_sender, appt_is_cross_project, appt_prompt_mins, cb_shortest_mins, cb_longest_mins, cb_max_attempts, cb_delivers_from, cb_percent, wgt_max_iterations, wgt_cof_for_missing, qre_sys_missing, qre_allow_missing, qre_is_whs_used, qre_browse_mode, qre_show_tel, qre_option_len, qre_rnd_option_thrs, qre_auto_fill, qre_fore_color, qre_back_color, qre_info_color, qre_need_check, qre_is_locked, qre_is_readonly, web_allow_refill, oth_input_method, oth_duty_table_title, notes) VALUES
(null, null, null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(l, '2024A0001', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 7302, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(2, '2024A0002', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1600, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(3, '2024A0003', null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, null, '02', '', '', 10, '', '', '', true, 'X', 'X', 10552, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(4, '2024A0003-1', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 3527, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(5, '2024A0003-2', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 2800, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(5, '2024A0003-2', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 2819, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(5, '2024A0003-2', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 5847, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(6, '2024A0003-3', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 4206, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(6, '2024A0003-3', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 5206, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(7, '2024A0004', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 2000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(7, '2024A0004', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 2000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(7, '2024A0004', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 2000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(7, '2024A0004', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 2300, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(8, '2024A0005', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1850, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(8, '2024A0005', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1650, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(8, '2024A0005', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1750, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(8, '2024A0005', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1850, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(9, '2024A0006', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1300, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(9, '2024A0006', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1300, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(9, '2024A0006', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1300, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(9, '2024A0006', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1300, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(9, '2024A0006', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1150, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1150, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1150, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1150, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1150, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1350, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1350, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(10, '2024A0007', null, 8, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1550, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(11, '2024A0008', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1200, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(11, '2024A0008', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1200, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(11, '2024A0008', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(11, '2024A0008', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(11, '2024A0008', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 850, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(12, '2024A0009', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 600, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(12, '2024A0009', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 600, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(13, '2024A0010', null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, null, '02', '', '', 10, '', '', '', true, 'X', 'X', 21679, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(14, '2024A0010-1', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 12537, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(14, '2024A0010-1', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 12537, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(14, '2024A0010-1', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 12537, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(14, '2024A0010-1', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 12537, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(14, '2024A0010-1', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 12537, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(15, '2024A0010-2', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 8263, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(15, '2024A0010-2', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3002, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(15, '2024A0010-2', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 5234, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(16, '2024A0010-3', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3908, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(16, '2024A0010-3', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3908, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(16, '2024A0010-3', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3908, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(16, '2024A0010-3', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3908, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(17, '2024A0011', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1350, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(18, '2024A0012', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(18, '2024A0012', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 950, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 2700, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 2700, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 3000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 5000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 5000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(19, '2024A0013', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 5000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(20, '2024A0014', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 2067, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(20, '2024A0014', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 1050, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(20, '2024A0014', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 2123, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(20, '2024A0014', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 1067, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 500, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 600, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 700, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 800, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 900, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 1000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(21, '2024A0015', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'P', '02', '', '', 10, '', '', '', true, 'X', 'X', 1100, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(22, '2024A0016', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 700, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(22, '2024A0016', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 800, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(22, '2024A0016', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 900, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1251, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1252, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1253, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1254, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1255, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1256, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1257, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 8, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1258, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(23, '2024A0017', null, 9, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1259, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(24, '2024A0018', null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, null, '02', '', '', 10, '', '', '', true, 'X', 'X', 6118, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(25, '2024A0018-1', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1064, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(25, '2024A0018-1', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1065, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(25, '2024A0018-1', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1066, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(25, '2024A0018-1', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1067, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(25, '2024A0018-1', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(26, '2024A0018-2', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 550, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(26, '2024A0018-2', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 650, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(26, '2024A0018-2', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 750, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(27, '2024A0018-3', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 1200, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(27, '2024A0018-3', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 2200, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(27, '2024A0018-3', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'W', '02', '', '', 10, '', '', '', true, 'X', 'X', 3200, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(28, '2024A0018-4', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 600, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(28, '2024A0018-4', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 700, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(28, '2024A0018-4', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 800, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(29, '2024A0018-5', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 5000, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(29, '2024A0018-5', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 500, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(30, '2024A0019', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1123, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(31, '2024A0020', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1500, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(31, '2024A0020', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'S', '02', '', '', 10, '', '', '', true, 'X', 'X', 1500, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(32, '2024A0021', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'E', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(33, '2024A0022', null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, null, '02', '', '', 10, '', '', '', true, 'X', 'X', 38912, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(34, '2024A0022-1', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 5524, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(34, '2024A0022-1', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 5524, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(34, '2024A0022-1', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 5624, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(35, '2024A0022-2', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 15870, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(35, '2024A0022-2', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 25870, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3409, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3509, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3609, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3709, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3809, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(36, '2024A0022-3', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3909, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3709, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3719, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3729, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3739, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3749, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3759, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(37, '2024A0022-4', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 3769, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1232, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1231, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1230, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1229, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1228, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1227, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1224, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 8, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1225, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 9, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1226, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 10, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1030, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 11, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1130, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 12, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1230, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 13, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1330, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 14, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1430, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 15, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1530, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 16, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1630, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 17, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1730, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 18, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1830, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 19, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1235, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(38, '2024A0023', null, 20, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'T', '02', '', '', 10, '', '', '', true, 'X', 'X', 1236, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(39, '2024A0024', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 4326, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(40, '2024A0025', null, 0, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, null, '02', '', '', 10, '', '', '', true, 'X', 'X', 2136, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(41, '2024A0025-1', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1065, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(41, '2024A0025-1', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1066, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(41, '2024A0025-1', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1067, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(41, '2024A0025-1', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 1, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1168, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 2, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1268, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 3, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1368, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 4, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1468, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 5, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1568, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 6, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1068, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 7, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1681, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 8, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1682, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', ''),
(42, '2024A0025-2', null, 9, 'static/images/public/cover_image.jpg', 'static/images/public/logo_image.jpg', 2, 'H', '02', '', '', 10, '', '', '', true, 'X', 'X', 1683, 12, 2, true, 20, null, 10, null, true, 'P', 3, 60, 180, 7, '19:30', 33.33, 20, 0, '9', false, false, 'E', true, 1, 4, false, '#...', '#...', '', false, false, false, false, '注音', '智晟公司訪員登班表', '');