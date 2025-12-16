# Seed canonical topics and tags for composer filters.
puts 'Seeding database...'

TaxonomySeeder.seed!

puts "Seeding completed!"
puts "  Topics: #{Topic.count}"
puts "  Tags: #{Tag.count}"

# Verify minimum requirements
if Topic.count.zero? || Tag.count.zero?
  puts "WARNING: Seeding may have failed. Topics or tags are missing."
else
  puts "Database is ready for use."
end

# =============================================================================
# SAMPLE DATA: Create realistic community content for demo purposes
# =============================================================================
puts "\n--- Seeding Sample Community Data ---"

# Skip if posts already exist (avoid duplicates on re-seed)
if Post.count > 0
  puts "Sample data already exists (#{Post.count} posts). Skipping..."
else
  # Create sample users (anonymous - will show pseudonyms)
  sample_users = [
    { email: 'student1@columbia.edu', password: 'password123' },
    { email: 'student2@columbia.edu', password: 'password123' },
    { email: 'student3@columbia.edu', password: 'password123' },
    { email: 'student4@barnard.edu', password: 'password123' },
    { email: 'student5@barnard.edu', password: 'password123' },
    { email: 'student6@columbia.edu', password: 'password123' },
    { email: 'student7@columbia.edu', password: 'password123' },
    { email: 'student8@barnard.edu', password: 'password123' },
    { email: 'student9@columbia.edu', password: 'password123' },
    { email: 'student10@columbia.edu', password: 'password123' },
    { email: 'student11@barnard.edu', password: 'password123' },
    { email: 'student12@columbia.edu', password: 'password123' }
  ]

  users = sample_users.map do |attrs|
    User.find_or_create_by!(email: attrs[:email]) do |u|
      u.password = attrs[:password]
      u.password_confirmation = attrs[:password]
    end
  end
  puts "  Created #{users.size} sample users"

  # Helper to find topic and tags
  def find_topic(name)
    Topic.find_by!(name: name)
  end

  def find_tags(*slugs)
    Tag.where(slug: slugs)
  end

  # Expanded sample posts with realistic college content
  sample_posts = [
    {
      title: "Best CS electives for junior year?",
      body: "I'm a CS major trying to plan my schedule for next semester. Already took OS and algorithms. What electives would you recommend? Thinking about ML, NLP, or computer graphics. Which ones have reasonable workloads?",
      topic: 'Academics',
      tags: [ 'courses/coms', 'academics' ],
      school: 'Columbia',
      course_code: 'COMS W4995'
    },
    {
      title: "Wien vs Schapiro for sophomores?",
      body: "Got my housing assignment and have to choose between Wien and Schapiro. Any thoughts on which is better? Heard Wien has bigger rooms but Schapiro is newer. Also wondering about the social scene in each.",
      topic: 'Housing',
      tags: [ 'housing', 'student-life' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Looking for Data Structures study group",
      body: "Anyone want to form a study group for COMS 3134? Midterm is in 3 weeks and I could use some help with trees and graphs. Usually free on Tuesday/Thursday evenings.",
      topic: 'Academics',
      tags: [ 'courses/coms', 'academics' ],
      school: 'Columbia',
      course_code: 'COMS W3134'
    },
    {
      title: "OPT application timeline question",
      body: "International student here. Planning to apply for OPT after graduation in May. When should I start the application process? Also, does ISSO have walk-in hours or do I need an appointment?",
      topic: 'General',
      tags: [ 'visas-immigration', 'international' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Good spots for quiet studying near campus?",
      body: "Butler is always packed and I can't focus in my dorm. Where do people go to study when the libraries are full? Bonus points if they have good coffee nearby.",
      topic: 'Campus Life',
      tags: [ 'student-life', 'resources' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Dealing with midterm stress",
      body: "Feeling really overwhelmed with 3 midterms next week. Does anyone have tips for managing stress during exam season? Also wondering if the counseling center is hard to get appointments at.",
      topic: 'Wellness',
      tags: [ 'mental-health', 'resources' ],
      school: 'Barnard',
      course_code: nil
    },
    {
      title: "Summer internship search tips?",
      body: "Junior looking for SWE internships for this summer. Applied to like 50 companies and only heard back from 3. Any advice on improving my resume or finding companies that are still hiring?",
      topic: 'Career',
      tags: [ 'career' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Best lunch spots near Lerner?",
      body: "Getting tired of JJ's and Ferris. What are some good affordable lunch options walking distance from campus? Preferably under $15.",
      topic: 'Campus Life',
      tags: [ 'student-life' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Selling textbooks - Calc III and Orgo",
      body: "Selling my textbooks from last semester:\n- Stewart Calculus (8th ed) - $40\n- Klein Organic Chemistry (3rd ed) - $50\n\nBoth in good condition with minimal highlighting. Can meet on campus.",
      topic: 'General',
      tags: [ 'marketplace' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "WiFi issues in Carman?",
      body: "Is anyone else having terrible WiFi in Carman lately? My connection keeps dropping during Zoom calls. Already tried resetting my router. Should I contact CUIT?",
      topic: 'General',
      tags: [ 'tech-support', 'housing' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Club recommendations for shy freshmen?",
      body: "Just started here and finding it hard to meet people. What clubs are welcoming to people who are a bit introverted? Looking for something low-key but social.",
      topic: 'Campus Life',
      tags: [ 'student-life', 'resources' ],
      school: 'Barnard',
      course_code: nil
    },
    {
      title: "Professor recs for Intro Psych?",
      body: "Need to fulfill a science requirement and thinking about Intro Psych. Who's good? I've heard mixed things about different professors. Looking for someone engaging who doesn't have impossible exams.",
      topic: 'Academics',
      tags: [ 'academics', 'advising' ],
      school: 'Barnard',
      course_code: 'PSYC UN1001'
    },
    {
      title: "Financial aid appeal process?",
      body: "My family's financial situation changed significantly this year. Has anyone gone through the financial aid appeal process? How long does it usually take and what documentation did you need?",
      topic: 'General',
      tags: [ 'financial-aid', 'resources' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "ODS accommodation experiences?",
      body: "Thinking about registering with ODS for my ADHD. What's the process like? Do professors generally respect the accommodations? Worried about being treated differently.",
      topic: 'Wellness',
      tags: [ 'accessibility-ods', 'mental-health' ],
      school: 'Columbia',
      course_code: nil
    },
    # New posts for more variety
    {
      title: "anyone else lowkey struggling in orgo rn??",
      body: "ngl i thought i was prepared but this class is hitting different. the exam average was a 52 and i somehow got below that lmao. anyone wanna study together or know good tutoring resources? im literally desperate at this point",
      topic: 'Academics',
      tags: [ 'academics' ],
      school: 'Columbia',
      course_code: 'CHEM UN2443'
    },
    {
      title: "Best coffee on campus? Need caffeine recommendations",
      body: "tbh im spending way too much money on coffee but i need it to survive. where do yall get your caffeine fix? looking for something thats not too expensive but also not garbage quality lol",
      topic: 'Campus Life',
      tags: [ 'student-life' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "How to deal with a difficult roommate situation?",
      body: "My roommate has been having people over super late every night and it's affecting my sleep and grades. We've talked about it but nothing changes. What are my options? Is it too late to switch rooms?",
      topic: 'Housing',
      tags: [ 'housing', 'student-life' ],
      school: 'Barnard',
      course_code: nil
    },
    {
      title: "Research opportunities for freshmen?",
      body: "I'm a first-year interested in getting involved in research, specifically in neuroscience. Is it realistic to start this early? How do I even approach professors about this? Any tips would be appreciated!",
      topic: 'Academics',
      tags: [ 'academics', 'career' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "gym way too crowded - alternatives?",
      body: "dodge is literally packed 24/7 and i hate waiting for equipment. does anyone know any affordable gyms near campus? or maybe less crowded times to go? trying to stay consistent with working out but this is making it so hard",
      topic: 'Wellness',
      tags: [ 'student-life', 'resources' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "What's the deal with Core Curriculum?",
      body: "Incoming freshman here trying to understand the Core requirements. Do most people actually enjoy these classes or is it just something to get through? Also which Core classes are the best/worst?",
      topic: 'Academics',
      tags: [ 'academics', 'advising' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Part-time job recommendations on campus?",
      body: "Looking for a part-time job that won't kill my GPA. What campus jobs have good pay and reasonable hours? Bonus if I can do homework during slow periods lol",
      topic: 'Career',
      tags: [ 'career', 'resources' ],
      school: 'Barnard',
      course_code: nil
    },
    {
      title: "Is double majoring worth it?",
      body: "I'm thinking about adding a second major (CS + Econ) but I'm worried about the workload. Did anyone here double major? Was it worth it or do you regret it? Trying to figure out if employers even care",
      topic: 'Academics',
      tags: [ 'academics', 'career', 'advising' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "Safe late-night food delivery options?",
      body: "Sometimes I'm studying super late and get hungry around 2am. What delivery options are actually safe and reliable at that hour? Had some sketchy experiences with random apps",
      topic: 'Campus Life',
      tags: [ 'student-life' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "How competitive is the pre-med track here?",
      body: "Thinking about going pre-med but I've heard horror stories about the competitiveness and curve. Is it really that bad? Or are people exaggerating? I don't want to burn out before I even apply to med school",
      topic: 'Academics',
      tags: [ 'academics', 'career' ],
      school: 'Columbia',
      course_code: nil
    },
    {
      title: "best spots to take a nap on campus?",
      body: "ok hear me out... sometimes u just need a power nap between classes. where are the best hidden spots to catch some Zs without being judged?? asking for myself not even gonna lie",
      topic: 'Campus Life',
      tags: [ 'student-life' ],
      school: 'Barnard',
      course_code: nil
    }
  ]

  # Create posts
  created_posts = []
  sample_posts.each_with_index do |post_data, idx|
    user = users[idx % users.size]
    topic = find_topic(post_data[:topic])
    tags = find_tags(*post_data[:tags])

    post = Post.new(
      user: user,
      topic: topic,
      title: post_data[:title],
      body: post_data[:body],
      school: post_data[:school],
      course_code: post_data[:course_code],
      status: 'open'
    )
    post.tags = tags
    post.save!
    post.update_column(:created_at, rand(1..21).days.ago)
    created_posts << post
  end
  puts "  Created #{created_posts.size} sample posts"

  # Expanded sample answers with realistic student language
  sample_answers = {
    0 => [ # CS electives post
      "Highly recommend ML! Prof Collins is great and the projects are interesting. Workload is manageable if you stay on top of readings.",
      "Graphics is super fun but time-consuming. Be ready to spend a lot of time on the ray tracer project. totally worth it tho if ur into that stuff",
      "NLP with Prof McKeown was one of my favorite classes. Final project lets you work on something you're actually interested in.",
      "tbh security is lowkey slept on. really practical stuff and not as much math as ML"
    ],
    1 => [ # Housing post
      "Wien for sure. Bigger rooms make a huge difference. The laundry situation is similar in both.",
      "Schapiro has way better lounges and study spaces. Wien's common areas are kind of meh.",
      "Lived in both - Wien freshman year, Schapiro sophomore year. Honestly both are fine, location is the same.",
      "pro tip: if u can get a corner room in wien its actually pretty nice. more natural light"
    ],
    2 => [ # Study group post
      "I'm down! Also struggling with AVL trees. DM me your number?",
      "Can I join? I'm pretty good with graphs but need help with heaps.",
      "yoo im in the same boat. thursdays work for me. butler 3rd floor?"
    ],
    3 => [ # OPT post
      "Start at least 90 days before graduation! ISSO appointments fill up fast during spring semester.",
      "Definitely book an ISSO appointment ASAP. They'll walk you through everything. The online portal is confusing.",
      "dont stress too much, the ISSO advisors are super helpful. just make sure u have all ur documents ready"
    ],
    4 => [ # Study spots post
      "Hungarian Pastry Shop on Amsterdam is my go-to. Good coffee, no one bothers you.",
      "Try the law library - it's less crowded than Butler and super quiet. game changer fr",
      "Joe Coffee in the journalism building has great atmosphere and usually has seats.",
      "Milstein at Barnard is nice too! Open to Columbia students.",
      "unpopular opinion but the business school library is underrated. less crowded after 5pm"
    ],
    5 => [ # Stress post
      "Counseling center appointments can take a week or two but they have same-day crisis appointments. Definitely reach out!",
      "Exercise helps me a lot. Even just a 20 min walk around campus clears my head.",
      "The app Calm has free access through Columbia. The sleep meditations are fire honestly",
      "also dont forget to eat properly during exam season. it sounds basic but it makes a huge difference"
    ],
    6 => [ # Internship post
      "Have you tried reaching out to alumni on LinkedIn? A lot of people are willing to refer. CCE can help with this too.",
      "Make sure your resume is ATS-friendly. I got way more callbacks after reformatting mine.",
      "Some companies do late hiring rounds in Feb/March. Don't give up!",
      "ngl the startup career fair is slept on. less competitive and they actually respond to apps",
      "leetcode grind is unfortunately necessary but start with easys and work ur way up"
    ],
    7 => [ # Lunch post
      "Shake Shack on 86th isn't walking distance but worth the subway ride honestly.",
      "Dig Inn on Broadway is healthy and portions are huge. Around $12-14.",
      "Mel's Burger Bar has great burgers and student discounts on Tuesdays!",
      "xi'an famous foods on broadway is amazing if u like spicy chinese food. the biang biang noodles are elite"
    ],
    10 => [ # Club post
      "Check out the board game club! Super chill vibes, no pressure to talk if you don't want to.",
      "Photography club is great for introverts - you can just walk around and take photos together.",
      "Volunteering clubs like CU in the City are nice because you're focused on the activity, not small talk.",
      "quiz bowl is surprisingly chill despite sounding intense lol. good people"
    ],
    11 => [ # Psych post
      "Take it with Prof Metcalfe if you can. She's tough but fair and her lectures are actually interesting.",
      "Avoid the Thursday section - it conflicts with a lot of other popular classes.",
      "the TAs for this class are super helpful during office hours btw"
    ],
    13 => [ # ODS post
      "The process was really straightforward for me. Had my documentation ready and got accommodations within 2 weeks.",
      "Most professors have been super understanding in my experience. Just email them at the start of the semester.",
      "Extended time on exams has been a lifesaver. Definitely worth registering.",
      "also u can get note-taking accommodations which is clutch for lectures"
    ],
    14 => [ # Orgo post
      "the orgo tutoring at milstein is free and actually helpful! go to the sunday sessions",
      "honestly organic chemistry tutor on youtube saved my grade. watch his videos before lecture",
      "study groups are essential for this class. solo studying doesnt work for most ppl",
      "ngl i failed the first exam and still ended up with a B+. the curve is real dont give up"
    ],
    15 => [ # Coffee post
      "Blue Java in Lerner is decent and accepts meal swipes. not the best but convenient",
      "Joe Coffee is pricey but worth it imo. their lattes are actually good",
      "hot take but the dining hall coffee with some oat milk isnt that bad if ur broke",
      "irving farm on broadway is my go-to. a bit of a walk but the vibes are immaculate"
    ],
    16 => [ # Roommate post
      "document everything and talk to your RA. they can help mediate the situation",
      "had the same issue freshman year. ended up switching rooms through housing and it was the best decision ever",
      "try the roommate agreement form - it sounds silly but having things in writing actually helps"
    ],
    17 => [ # Research post
      "definitely possible as a freshman! email professors whose research interests you with a specific reason why",
      "SURF program in the summer is great for getting started. applications usually open in spring",
      "some profs prefer students who have taken relevant courses but others are happy to train you from scratch"
    ],
    18 => [ # Gym post
      "try going before 7am or after 9pm. way less crowded at those times",
      "planet fitness on 125th is like $10/month and 24 hours. worth it for the convenience",
      "also check out the smaller barnard gym if u have access. less crowded"
    ],
    19 => [ # Core post
      "lit hum is honestly great if you get a good section. frontiers of science is rough tho ngl",
      "CC varies a lot depending on professor. ask around before picking sections",
      "unpopular opinion but i actually loved UWriting. depends on the instructor tho",
      "art hum is a nice break from other classes. museum visits are actually fun"
    ],
    20 => [ # Part-time job post
      "library jobs are the move. lots of downtime for studying",
      "residential life desk attendant is pretty chill. night shifts are quiet",
      "tutoring through the writing center pays well if ur good at writing"
    ],
    21 => [ # Double major post
      "did CS + Math, workload was manageable bc of overlap. econ has less overlap so might be harder",
      "employers honestly dont care that much unless its a very relevant combo. focus on internships instead",
      "i regret double majoring tbh. wish i had more time for extracurriculars and just enjoying college"
    ],
    22 => [ # Late night food post
      "insomnia cookies delivers until 3am and accepts dining dollars",
      "uber eats usually has halal carts delivering late. might be sketchy quality tho lol",
      "JJ's is open late and takes meal swipes. the quesadillas are solid"
    ],
    23 => [ # Pre-med post
      "its competitive but not cutthroat if u find the right people. study groups help a lot",
      "the curve is real in some classes but not all. orgo is rough, bio is more fair",
      "honestly the hardest part is juggling clinical experience + research + classes + social life. time management is key"
    ],
    24 => [ # Nap spots post
      "butler 209 has those comfy chairs in the back. prime napping real estate",
      "lerner piano lounge when its empty is elite. the couches are surprisingly comfortable",
      "the lawn on a nice day. just bring a blanket and set an alarm lol",
      "controversial but the religion library is so quiet u will definitely fall asleep"
    ]
  }

  answer_count = 0
  created_answers = []
  sample_answers.each do |post_idx, answers|
    post = created_posts[post_idx]
    next unless post

    answers.each_with_index do |answer_body, ans_idx|
      # Use a different user than the post author
      answerer = users[(post_idx + ans_idx + 1) % users.size]
      answer = Answer.create!(
        post: post,
        user: answerer,
        body: answer_body,
        created_at: post.created_at + rand(1..72).hours
      )
      created_answers << answer
      answer_count += 1
    end
  end
  puts "  Created #{answer_count} sample answers"

  # Add answer comments (대댓글)
  sample_comments = [
    { answer_idx: 0, body: "seconding this! ML projects are actually fun" },
    { answer_idx: 1, body: "wait how time consuming are we talking? like more than OS?" },
    { answer_idx: 4, body: "omg yes hungarian pastry shop is so underrated" },
    { answer_idx: 5, body: "the law library tip is gold. tysm" },
    { answer_idx: 8, body: "wait we can use the business school library??" },
    { answer_idx: 10, body: "this! exercise is literally free therapy" },
    { answer_idx: 12, body: "the linkedin alumni thing actually worked for me. got 3 interviews from cold messages" },
    { answer_idx: 15, body: "agreed leetcode is necessary evil. hackerrank is also good for practice" },
    { answer_idx: 18, body: "xi'an is SO good. the spicy cumin lamb is my go-to" },
    { answer_idx: 22, body: "board game club sounds perfect for me actually. when do they meet?" },
    { answer_idx: 26, body: "this gives me hope lol. currently sitting at a 45 on the first exam" },
    { answer_idx: 28, body: "organic chemistry tutor is goated. wish i found him earlier" },
    { answer_idx: 32, body: "facts irving farm is worth the walk" },
    { answer_idx: 35, body: "did housing give u a hard time about switching rooms mid semester?" },
    { answer_idx: 38, body: "SURF is amazing! highly recommend applying" },
    { answer_idx: 42, body: "7am gym crew rise up" },
    { answer_idx: 46, body: "wait art hum museum visits sound fun. which museums do you go to?" },
    { answer_idx: 50, body: "library jobs are clutch. applied for one last semester" },
    { answer_idx: 54, body: "insomnia cookies is dangerous for my wallet ngl" },
    { answer_idx: 58, body: "the orgo curve saved my life fr" },
    { answer_idx: 60, body: "butler 209 is my secret spot too lmao" },
    { answer_idx: 61, body: "the religion library is TOO quiet. i get anxious there" }
  ]

  comment_count = 0
  created_comments = []
  sample_comments.each do |comment_data|
    answer = created_answers[comment_data[:answer_idx]]
    next unless answer

    commenter = users.sample
    # Make sure commenter is different from answer author
    commenter = users.sample while commenter == answer.user

    comment = AnswerComment.create!(
      answer: answer,
      user: commenter,
      body: comment_data[:body],
      created_at: answer.created_at + rand(1..24).hours
    )
    created_comments << comment
    comment_count += 1
  end
  puts "  Created #{comment_count} sample answer comments"

  # Add likes to posts
  post_like_count = 0
  created_posts.each do |post|
    # Random number of users like each post
    likers = users.sample(rand(2..8))
    likers.each do |liker|
      next if liker == post.user # Don't like own post
      Like.create!(user: liker, post: post, vote_type: Like::UPVOTE)
      post_like_count += 1
    end
  end

  # Some downvotes for realism
  created_posts.sample(5).each do |post|
    disliker = (users - [ post.user ]).sample
    existing_like = Like.find_by(user: disliker, post: post)
    if existing_like
      existing_like.update!(vote_type: Like::DOWNVOTE)
    else
      Like.create!(user: disliker, post: post, vote_type: Like::DOWNVOTE)
      post_like_count += 1
    end
  end
  puts "  Created #{post_like_count} post likes"

  # Add likes to answers
  answer_like_count = 0
  created_answers.each do |answer|
    # Random number of users like each answer
    likers = users.sample(rand(1..6))
    likers.each do |liker|
      next if liker == answer.user # Don't like own answer
      AnswerLike.create!(user: liker, answer: answer, vote_type: AnswerLike::UPVOTE)
      answer_like_count += 1
    end
  end

  # Some downvotes on answers
  created_answers.sample(8).each do |answer|
    disliker = (users - [ answer.user ]).sample
    existing = AnswerLike.find_by(user: disliker, answer: answer)
    if existing
      existing.update!(vote_type: AnswerLike::DOWNVOTE)
    else
      AnswerLike.create!(user: disliker, answer: answer, vote_type: AnswerLike::DOWNVOTE)
      answer_like_count += 1
    end
  end
  puts "  Created #{answer_like_count} answer likes"

  # Add likes to answer comments
  comment_like_count = 0
  created_comments.each do |comment|
    # Random number of users like each comment
    likers = users.sample(rand(0..4))
    likers.each do |liker|
      next if liker == comment.user # Don't like own comment
      AnswerCommentLike.create!(user: liker, answer_comment: comment, vote_type: AnswerCommentLike::UPVOTE)
      comment_like_count += 1
    end
  end
  puts "  Created #{comment_like_count} answer comment likes"

  # Mark some posts as solved with accepted answers
  solved_posts = [ created_posts[2], created_posts[4], created_posts[14] ].compact
  solved_count = 0
  solved_posts.each do |post|
    next unless post.answers.any?
    # Pick the answer with highest score as accepted
    best_answer = post.answers.max_by(&:net_score) || post.answers.first
    post.update!(accepted_answer: best_answer, status: 'solved', locked_at: Time.current)
    solved_count += 1
  end
  puts "  Marked #{solved_count} posts as solved"

  puts "\n--- Sample Data Seeding Complete! ---"
  puts "  Total Posts: #{Post.count}"
  puts "  Total Answers: #{Answer.count}"
  puts "  Total Answer Comments: #{AnswerComment.count}"
  puts "  Total Post Likes: #{Like.count}"
  puts "  Total Answer Likes: #{AnswerLike.count}"
  puts "  Total Comment Likes: #{AnswerCommentLike.count}"
  puts "  Total Users: #{User.count}"
end

# =============================================================================
# MODERATOR ACCOUNTS & DEMO MODERATION DATA
# =============================================================================
puts "\n--- Seeding Moderator Data ---"

# Create moderator account
moderator = User.find_or_create_by!(email: 'moderator@columbia.edu') do |u|
  u.password = 'password123'
  u.password_confirmation = 'password123'
  u.role = :moderator
end
# Ensure role is moderator even if user existed
moderator.update!(role: :moderator) unless moderator.moderator?
puts "  Created/updated moderator: #{moderator.email}"

# Create demo moderation content (only if none exists)
if Post.where.not(redaction_state: 'visible').count == 0 && Post.where(ai_flagged: true).count == 0
  sample_user = User.where.not(role: :moderator).first
  topic = Topic.first
  tag = Tag.first

  if sample_user && topic && tag
    # 1. Redacted post (policy violation)
    policy_post = Post.create!(
      user: sample_user,
      topic: topic,
      tags: [tag],
      title: "Looking for exam answers - will pay!!",
      body: "Anyone have answers for tomorrow's final? Can Venmo you $50. DM me ASAP.",
      school: 'Columbia',
      status: 'open'
    )
    RedactionService.redact_post(
      post: policy_post,
      moderator: moderator,
      reason: 'academic_integrity'
    )
    puts "  Created redacted post: academic_integrity"

    # 2. AI-flagged post (mental health concern)
    ai_flagged_post = Post.create!(
      user: sample_user,
      topic: Topic.find_by(name: 'Wellness') || topic,
      tags: [Tag.find_by(slug: 'mental-health') || tag],
      title: "Feeling overwhelmed and hopeless lately...",
      body: "Everything feels like too much. I don't know what to do anymore. Nothing seems to matter and I can't see things getting better. Has anyone else felt this way?",
      school: 'Columbia',
      status: 'open',
      ai_flagged: true,
      ai_categories: { 'self-harm' => true, 'harassment' => false, 'violence' => false },
      ai_scores: { 'self-harm' => 0.72, 'harassment' => 0.05, 'violence' => 0.02 },
      screened_at: Time.current
    )
    puts "  Created AI-flagged post: self-harm concern"

    # 3. User-reported post
    reported_post = Post.create!(
      user: sample_user,
      topic: topic,
      tags: [tag],
      title: "This professor is terrible and should be fired",
      body: "Prof X in the CS department is the worst. They don't answer emails, grade unfairly, and clearly don't care about students. Avoid at all costs!!!",
      school: 'Columbia',
      status: 'open',
      reported: true,
      reported_at: 2.hours.ago,
      reported_reason: 'harassment'
    )
    puts "  Created user-reported post: harassment"

    # 4. AI-flagged post with appeal
    appealed_post = Post.create!(
      user: sample_user,
      topic: topic,
      tags: [tag],
      title: "Intense debate about political science class",
      body: "We had a heated discussion in class today about controversial topics. Some students got really passionate and voices were raised. Is this normal for poli sci classes?",
      school: 'Columbia',
      status: 'open',
      ai_flagged: true,
      ai_categories: { 'hate' => true, 'violence' => false },
      ai_scores: { 'hate' => 0.45, 'violence' => 0.12 },
      screened_at: 1.day.ago,
      appeal_requested: true,
      appeal_requested_at: 12.hours.ago
    )
    puts "  Created AI-flagged post with appeal: hate speech (false positive)"

    puts "  Created 4 demo moderation posts for dashboard testing"
  else
    puts "  Skipped moderation demo data (missing user/topic/tag)"
  end
else
  puts "  Moderation demo data already exists. Skipping..."
end

puts "\n--- Moderator Data Seeding Complete! ---"
puts "  Moderators: #{User.where(role: :moderator).count}"
puts "  Redacted Posts: #{Post.where.not(redaction_state: 'visible').count}"
puts "  AI-Flagged Posts: #{Post.where(ai_flagged: true).count}"
puts "  Reported Posts: #{Post.where(reported: true).count}"
