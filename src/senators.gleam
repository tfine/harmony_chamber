//// Harmony Chamber senator roster
//// Comprehensive biographies for all 100 senators.
//// AGATA / Harmony specialized Senate
//// 100 fictional senators for the AGATA project.

pub type Senator {
  Senator(id: String, name: String, state: String, biography: String)
}

pub fn all_senators() -> List(Senator) {
  [
    // -------------------------------------------------
    // I. Regenerative Agriculture & Soil (Farm) 1–10
    // -------------------------------------------------
    Senator(
      id: "amara_okafor",
      name: "Amara Okafor",
      state: "Farm",
      biography: "Amara Okafor was born in Enugu, Nigeria and spent childhood afternoons between crowded streets and family plots where older relatives still read the soil by smell and feel.\n\nShe studied soil science and agronomy, then joined a multinational agribusiness modelling fertilizer regimes, only to leave after watching top-down projects worsen erosion and farmer debt in West Africa. She retrained alongside smallholders and agroecologists, learning low-cost ways to rebuild fertility with cover crops, biochar, and layered compost.\n\nAt AGATA she serves as a kind of soil architect, arguing that every major decision must be traceable to improved soil structure and biodiversity, even if that means slower growth or more manual labor in the short term.",
    ),
    Senator(
      id: "caleb_hightower",
      name: "Caleb Hightower",
      state: "Farm",
      biography: "Caleb Hightower grew up in a small Georgia town where the family shop fixed tractors, church vans, and anything else dragged in on flatbeds.\n\nHe never finished a formal degree but learned hydraulics, welding, and field repairs on the job, later apprenticing on regenerative grazing operations that replaced diesel horsepower with portable fencing and animal impact. After a decade traveling from ranch to ranch he built a reputation for coaxing another ten years out of supposedly dead equipment.\n\nOn the AGATA Senate he fights for realistic maintenance plans, worker training on tools, and grazing schemes that match land and budget, always asking what can be fixed, repurposed, or animal-powered before anything new is bought on credit.",
    ),
    Senator(
      id: "liying_chen",
      name: "Dr. Liying Chen",
      state: "Farm",
      biography: "Liying Chen was raised in a rice-growing village in southern China where the boundaries between paddy, vegetable patch, and home garden were fluid and constantly renegotiated.\n\nShe studied plant ecology and landscape design, mapping multi-species polycultures in East and Southeast Asia before consulting on urban food forests. Frustrated by ornamental green projects that ignored food and farmers, she shifted to working directly with cooperatives and small farms.\n\nIn the AGATA Senate she designs intercropping patterns, agroforestry rows, and shade layers that make the land feel like a living ecosystem rather than a grid of single crops, pushing her colleagues to choose complexity and resilience over clean drone shots of perfect rows.",
    ),
    Senator(
      id: "rafael_dominguez",
      name: "Rafael \"Rafa\" Domínguez",
      state: "Farm",
      biography: "Rafael Domínguez grew up in San Antonio kitchens, spending more time on crate deliveries and prep lists than on his own homework.\n\nAfter years on the line in busy restaurants, he stumbled into intensive market gardening and discovered that a well-planned half acre could feed both households and restaurants with surprising reliability. He became known for obsessive planting calendars, wash/pack workflows, and CSA spreadsheets that matched what the soil and staff could actually deliver.\n\nOn the AGATA Senate he is the relentless voice asking what can truthfully be harvested, washed, packed, and sold this week, translating grand farm visions into bed maps, harvest boxes, and cash flow that keep workers paid on time.",
    ),
    Senator(
      id: "soraya_haddad",
      name: "Soraya Haddad",
      state: "Farm",
      biography: "Soraya Haddad was born in Detroit to a Lebanese mechanic and an Appalachian nurse, inheriting both old-world seed stories and a backyard tomato ferocity.\n\nShe drifted through community college before finding her vocation in a small seed library, eventually traveling across the U.S. and Lebanon collecting heirloom varieties and documenting the family histories attached to them. Her notebooks track flavor, drought tolerance, and the songs people sing while shelling beans.\n\nIn the AGATA Senate she treats the seed bank as constitutional infrastructure rather than a side project, arguing that every planting plan and cultural event should deepen the farm’s living archive of seeds and stories.",
    ),
    Senator(
      id: "malik_jefferson",
      name: "Malik Jefferson",
      state: "Farm",
      biography: "Malik Jefferson grew up in rural Arkansas and took a job at an industrial chicken plant straight out of high school, learning firsthand what efficiency can do to bodies and towns.\n\nA chance visit to a pasture-based poultry operation convinced him there had to be another way. He retrained with humane livestock advocates, mastering rotational grazing, mobile coops, and integrating animals into whole-farm fertility.\n\nOn the AGATA Senate he balances animal welfare, worker safety, and economic survival, designing livestock systems that heal land and offer dignified work instead of repeating the cruelty he escaped.",
    ),
    Senator(
      id: "ingrid_holm",
      name: "Dr. Ingrid Holm",
      state: "Farm",
      biography: "Ingrid Holm grew up in a Swedish port city watching cargo ships dump waste while inland farmers struggled with expensive fertilizers.\n\nShe trained as a civil engineer and waste-management specialist, then pivoted into compost engineering after realizing how much value was being buried or burned. Her work has ranged from city-scale compost facilities to small on-farm manure systems that control runoff and pathogens.\n\nAt AGATA she designs compost yards, runoff channels, and manure handling that turn every waste stream into a fertility engine, insisting that environmental compliance be folded into beautiful, teachable systems.",
    ),
    Senator(
      id: "ayo_olatunji",
      name: "Ayo Olatunji",
      state: "Farm",
      biography: "Ayo Olatunji grew up in a Nigerian–British family in Birmingham, toggling between spreadsheets at a warehouse job and weekends volunteering at a community garden.\n\nHe taught himself basic coding to track bed rotations and yields, eventually building simple open-source tools that small farms could actually use on their phones. His favorite compliment is when farmers forget the software is there because it fits their rhythms.\n\nOn the AGATA Senate he advocates for small, accurate farm datasets, pencil-and-paper backups, and worker ownership of information, arguing that technology should clarify the fields, not distract from them.",
    ),
    Senator(
      id: "etta_may_richardson",
      name: "Etta May Richardson",
      state: "Farm",
      biography: "Etta May Richardson spent four decades cooking in Pee Dee school cafeterias, stretching budgets and still sending kids through the line with hot plates and a greeting.\n\nShe started one of the district’s first tiny school gardens behind a trailer, growing collards, sweet potatoes, and herbs the children could recognize in their lunches. Over time she learned which vegetables kids would try if they helped plant or chop them.\n\nIn the AGATA Senate she anchors farm planning in real local appetites, pushing for crops and cooking plans that feed nearby families first and treating flavor as a form of community health.",
    ),
    Senator(
      id: "tanvi_rao",
      name: "Tanvi Rao",
      state: "Farm",
      biography: "Tanvi Rao grew up in coastal India watching monsoon calendars drift and cyclone tracks wobble closer to home year after year.\n\nShe became an agronomist specialized in climate-resilient cropping, modelling how erratic rainfall and heat waves would collide with farmer debt cycles. Her work, often done with co-ops, prizes redundancy: multiple water sources, backup crops, shelterbelts, and grain stores.\n\nOn the AGATA Senate she pushes for redundant water, diversified cropping, and storm-ready infrastructure so the farm can ride out bad seasons without sacrificing workers or long-term soil health.",
    ),

    // -------------------------------------------------
    // II. Water, Climate & Ecology (Ecology) 11–18
    // -------------------------------------------------
    Senator(
      id: "jonah_redbird",
      name: "Jonah Redbird",
      state: "Ecology",
      biography: "Jonah Redbird is an Indigenous hydrologist and community educator who insists that every well is part of a whole watershed.\n\nHe has worked with tribes, small towns, and riverkeepers to map how logging, culverts, and cul-de-sacs reshape floods and droughts over decades. His workshops mix maps, stories, and site walks, teaching people to see ridge lines, swales, and forgotten wetlands again.\n\nIn the AGATA Senate he treats every building, road, and pond as a move in the larger watershed, pushing for designs that slow water, recharge aquifers, and protect downstream neighbors from floods and thirst alike.",
    ),
    Senator(
      id: "mireille_aubert",
      name: "Dr. Mireille Aubert",
      state: "Ecology",
      biography: "Mireille Aubert grew up near the Camargue wetlands in France, fascinated by reeds, flamingos, and the way some ditches stayed alive while others went stagnant.\n\nShe trained as a wetland scientist and worked on restoring rice paddies, marshes, and floodplains across Europe and West Africa. Her specialty is low-tech water retention landscapes—swales, ponds, slow-drain systems—that can be maintained with shovels and local know-how.\n\nAt AGATA she designs a patchwork of ponds, ditches, and wetlands that double as habitat and drought buffer, arguing that the farm’s real reservoir is the sponge-like landscape under everyone’s feet.",
    ),
    Senator(
      id: "hollis_greene",
      name: "Hollis Greene",
      state: "Ecology",
      biography: "Hollis Greene is an amateur meteorologist and Pee Dee history buff who has kept a handwritten diary of storms, frosts, and heat waves for more than forty years.\n\nHe cross-references his notes with historical weather records and oral histories from elders who remember floods that never made the news. For him, climate is not an abstract graph but a series of specific mornings when the corn burned or the river rose.\n\nIn the AGATA Senate he grounds high-tech climate models in local experience, warning when people are about to repeat painful patterns because they have forgotten how often the river has jumped its banks.",
    ),
    Senator(
      id: "samira_bashir",
      name: "Dr. Samira Bashir",
      state: "Ecology",
      biography: "Samira Bashir trained as a climate scientist focused on soil carbon and agroforestry, splitting her time between satellite data and barefoot fieldwork.\n\nShe has helped design projects where tree belts, hedgerows, and grazing adjustments significantly increased carbon storage without crushing farmers under certification schemes. Her notebooks are full of carbon budgets scribbled next to sketches of windbreaks and shelterbelts.\n\nOn the AGATA Senate she runs sober carbon and emission budgets, cutting through hype and insisting that claims of climate positivity match measured reality on the ground and over time.",
    ),
    Senator(
      id: "thandi_maseko",
      name: "Thandi Maseko",
      state: "Ecology",
      biography: "Thandi Maseko grew up in a South African village where pollinators meant both honey and the promise of fruit in lean years.\n\nTrained as a field biologist, she studied bees, butterflies, and bats across fragmented landscapes, learning how small strips of blooming plants could hold whole communities together. She prefers hedgerows and weedy corners to pristine lawns.\n\nIn the AGATA Senate she designs flowering corridors, insect hotels, and bird habitat that plug right into farm operations, treating pollinators as co-workers whose needs must be planned into every map.",
    ),
    Senator(
      id: "owen_mccray",
      name: "Owen McCray",
      state: "Ecology",
      biography: "Owen McCray is a forester from rural North Carolina who spent his early career on wildland fire crews, learning how quickly a stand of pines can turn into a wall of flame.\n\nHe later specialized in controlled burns, thinning, and defensible-space planning for small communities tucked into woods. His practical focus is always on evacuation routes, water access, and where embers are most likely to land.\n\nOn the AGATA Senate he studies the property’s woods, fuel loads, and building placements, pushing for annual fire drills, shaded firebreaks, and simple protocols that keep both forests and people safe.",
    ),
    Senator(
      id: "julia_costa",
      name: "Dr. Júlia Costa",
      state: "Ecology",
      biography: "Júlia Costa is an ecologist who learned to love plants by pulling invasive vines off fruit trees in her grandparents’ Brazilian backyard.\n\nHer research has focused on invasive species dynamics and long-term management, teaching her that some plants can be eradicated while others must be managed indefinitely. She advocates for decade-long, staged strategies rather than one-off heroic cleanups.\n\nIn the AGATA Senate she designs realistic management plans for kudzu, privet, and feral hogs, helping the project commit to steady, long-term care instead of boom-and-bust campaigns.",
    ),
    Senator(
      id: "aiden_park",
      name: "Aiden Park",
      state: "Ecology",
      biography: "Aiden Park is a Korean American ecologist who fell in love with moths and bats during late-night surveys in urban parks.\n\nHis work tracks how light and sound pollution fragment nocturnal ecosystems, and he has helped towns redesign street lighting and nightlife around both safety and starlight. He brings headphones and star maps to community meetings.\n\nOn the AGATA Senate he advocates for dark-sky zones, red-lamped paths, and night walks as both ecological interventions and performances, designing a nightlife that respects owls, insects, and people who need quiet.",
    ),

    // -------------------------------------------------
    // III. Co-op Economics & Labor (Coop) 19–30
    // -------------------------------------------------
    Senator(
      id: "rosa_delgado",
      name: "Dr. Rosa Delgado",
      state: "Coop",
      biography: "Rosa Delgado grew up in a border town where cousins worked in factories, fields, and informal economies, and dinner table talk rarely matched the legal categories on pay stubs.\n\nShe became a lawyer and then a co-op constitutional specialist, helping draft modern worker co-op statutes in several states while sitting at kitchen tables translating bylaws into plain language. Her office is lined with annotated constitutions from co-ops that survived crises and those that didn’t.\n\nOn the AGATA Senate she obsesses over governance documents, profit allocation, and member education, insisting that every worker be able to explain the rules of the co-op in their own words.",
    ),
    Senator(
      id: "deshawn_carter",
      name: "DeShawn \"DJ\" Carter",
      state: "Coop",
      biography: "DeShawn Carter worked his way from night stocker to shift supervisor in a sprawling distribution warehouse on the outskirts of Atlanta.\n\nThere he learned how arbitrary schedule changes wrecked lives, and he became an informal organizer, building spreadsheets and group chats to coordinate childcare and carpooling. Later he joined a worker center, designing better rostering systems with and for low-wage workers.\n\nIn the AGATA Senate he pushes for transparent scheduling boards, predictable rotations, and paid experimentation blocks, treating time as a core co-op asset rather than a disposable input.",
    ),
    Senator(
      id: "priya_menon",
      name: "Priya Menon",
      state: "Coop",
      biography: "Priya Menon is an accountant who grew up helping her parents run a corner grocery in New Jersey, watching every invoice and coupon matter.\n\nShe trained as a CPA and then shifted to working almost exclusively with co-ops and small nonprofits, building spreadsheets that normal people can understand. Her specialty is turning cash-flow stress into shared plans instead of panic.\n\nOn the AGATA Senate she keeps finances boring, legible, and co-op centered, championing open books, weekly cash snapshots, and worker training so budgets become a shared language rather than a private mystery.",
    ),
    Senator(
      id: "marcus_kowalski",
      name: "Marcus Kowalski",
      state: "Coop",
      biography: "Marcus Kowalski grew up near a highway interchange in Ohio, surrounded by truck stops, diesel fumes, and the strange 24/7 economy of the road.\n\nHe studied logistics and rural economics informally—first as a night-shift cashier, later as a dispatcher and union researcher. He has a feel for fuel prices, delivery times, and where people actually stop when they say they are just passing through.\n\nIn the AGATA Senate he thinks about how the farm stand, café, and festivals can intercept existing flows of trucks, tourists, and commuters, turning a remote site into a necessary stop instead of a hidden gem.",
    ),
    Senator(
      id: "hyejin_park",
      name: "Hyejin Park",
      state: "Coop",
      biography: "Hyejin Park is a sociologist of care work who spent her twenties interviewing home health aides, nannies, and daughters who became nurses because no one else would.\n\nHer research tracks how exhaustion, low pay, and invisible labor underpin every flashy economic success story. She has helped design co-op models where care workers run the show and benefit from the surplus they create.\n\nOn the AGATA Senate she insists that child care, elder care, and rest be treated as core infrastructure, advocating for on-site care stipends, rotating rest weeks, and policies that respect invisible labor as central, not peripheral.",
    ),
    Senator(
      id: "lionel_baptiste",
      name: "Lionel Baptiste",
      state: "Coop",
      biography: "Lionel Baptiste spent twenty years as a union shop steward in a southern textile mill, guiding co-workers through layoffs, injuries, and management games.\n\nHe became known for his small notebook of grievances and his ability to listen longer than anyone else in the room. After the mill closed he helped form a workers’ committee that negotiated retraining and land access.\n\nOn the AGATA Senate he designs internal justice processes and conflict resolution pathways, arguing that the health of the project depends on how it handles its hardest conversations.",
    ),
    Senator(
      id: "giulia_romano",
      name: "Giulia Romano",
      state: "Coop",
      biography: "Giulia Romano grew up between a small Italian hill town and a co-op grocery in Bologna where her aunt worked the cheese counter and explained margins between customers.\n\nShe became a consultant helping co-ops avoid the trap of chasing hockey-stick growth at the expense of member control and survival. Her favorite case studies are cooperatives that deliberately stayed small and resilient.\n\nIn the AGATA Senate she is the voice of slow growth, stress-testing expansion plans and asking whether each new venture deepens local roots or drags the project toward burnout and debt.",
    ),
    Senator(
      id: "yana_petrova",
      name: "Yana Petrova",
      state: "Coop",
      biography: "Yana Petrova is a geographer who left academia after too many conferences about the tragedy of the commons that never involved actual commoners.\n\nShe began working with land trusts and community gardens, mapping who really used what spaces and which rules helped or harmed them. Her favorite projects involve nested commons: shared responsibilities without one monolithic owner.\n\nOn the AGATA Senate she helps design land governance and easements so that future residents, neighbors, and workers can share power over fields, woods, and housing without re-creating a landlord class.",
    ),
    Senator(
      id: "pastor_leon_wright",
      name: "Pastor Leon Wright",
      state: "Coop",
      biography: "Leon Wright is a bivocational pastor and credit-union board member from the Carolinas whose ministry has always included spreadsheets and soup kitchens.\n\nHe understands the quiet power of church budgets, benevolence funds, and informal lending circles. Over the years he has brokered deals between congregations, co-ops, and city halls who barely spoke to one another.\n\nIn the AGATA Senate he advises on partnerships with local churches and faith networks, pushing for shared risk and shared benefit instead of one-way fundraising appeals.",
    ),
    Senator(
      id: "chiamaka_nwosu",
      name: "Chiamaka Nwosu",
      state: "Coop",
      biography: "Chiamaka Nwosu worked in mainstream microfinance long enough to see how easily loans could become new chains instead of ladders.\n\nShe left to design truly fair microloan and grant schemes with migrant groups, domestic workers, and undocumented entrepreneurs, often pairing money with legal and language support. Her programs are judged by who feels safe applying, not just repayment rates.\n\nOn the AGATA Senate she helps build small, just financing tools for local side hustles and co-op spinoffs, constantly asking who is quietly excluded from opportunity.",
    ),
    Senator(
      id: "ella_jo_simmons",
      name: "Ella Jo Simmons",
      state: "Coop",
      biography: "Ella Jo Simmons spent three decades as a diner waitress along a trucking corridor, becoming the unofficial therapist for regulars, new hires, and exhausted managers.\n\nShe learned to read a room at a glance, handle a rush without snapping, and quietly train younger servers in survival skills the employee handbook never mentioned. Later she began teaching customer-service and de-escalation workshops.\n\nOn the AGATA Senate she advocates that training and emotional labor in hospitality spaces be recognized and compensated, arguing that a barn café or roadside stand lives or dies on the quality of its front-of-house care.",
    ),
    Senator(
      id: "tomas_anders",
      name: "Dr. Tomas Anders",
      state: "Coop",
      biography: "Tomas Anders is an economist who turned away from stock indexes to study how rural towns actually survive plant closures, hurricanes, and commodity crashes.\n\nHe builds scenario plans with communities, sketching futures where things go better, worse, or just sideways and exploring how different choices now echo later. His reports always include both spreadsheets and storylines.\n\nIn the AGATA Senate he draws up multiple futures—good and bad—and steers the project toward buffers: reserves, crop mixes, and multi-income streams that can hold when shocks arrive.",
    ),

    // -------------------------------------------------
    // IV. Law, Governance & Ethics (Governance) 31–38
    // -------------------------------------------------
    Senator(
      id: "nadia_el_khalil",
      name: "Dr. Nadia El-Khalil",
      state: "Governance",
      biography: "Nadia El-Khalil is a political scientist who fell in love with democracy not in capitals but in cramped town halls where everyone already knows everyone’s business.\n\nHer research on small-town councils and informal power networks taught her that bylaws are only half the story; gossip, kinship, and grudges often carry the rest. She has helped towns redesign their meeting formats and public notices to match how people actually communicate.\n\nOn the AGATA Senate she works to ensure that governance structures fit Southern rural realities, paying attention to who would hear about a meeting, feel welcome in a room, and trust a vote.",
    ),
    Senator(
      id: "harold_mcmillan",
      name: "Judge Harold McMillan (Ret.)",
      state: "Governance",
      biography: "Harold McMillan spent decades as a county judge in a mixed rural–small city district, presiding over everything from fence-line disputes to zoning fights and family land battles.\n\nHe became known for long drives to visit contested properties himself, listening quietly on front porches before ruling. His experience taught him that small legal details can carry generations of consequence.\n\nIn the AGATA Senate he offers clear-eyed readings of legal risk and opportunity, reminding colleagues that the clerk’s office, county commission, and neighbors’ memories matter as much as visionary manifestos.",
    ),
    Senator(
      id: "eleni_papadopoulos",
      name: "Dr. Eleni Papadopoulos",
      state: "Governance",
      biography: "Eleni Papadopoulos is a moral philosopher who always insisted on doing fieldwork, spending as much time with organizers and co-op members as with texts.\n\nShe has helped movements and tech collectives translate abstract values into checklists, questions, and decision points they can actually use under pressure. Her workshops often end with people drafting their own red lines and repair practices.\n\nOn the AGATA Senate she weaves ethics into every bill, posing uncomfortable but necessary questions about consent, power, and unintended consequences before big moves are made.",
    ),
    Senator(
      id: "maureen_riley",
      name: "Maureen \"Mo\" Riley",
      state: "Governance",
      biography: "Maureen Riley learned grants from both sides of the table: first as a burnt-out nonprofit writer chasing foundations, then as a program officer reading hundreds of awkward proposals.\n\nShe developed a knack for translating community priorities into funder language without sanding off the edges, and for saying no to grants that would quietly warp an organization’s work. Her files are full of rejected buzzwords crossed out in red pen.\n\nOn the AGATA Senate she keeps the project from letting grant timelines drive its soul, helping shape narratives that bring resources without turning AGATA into a brand-first operation.",
    ),
    Senator(
      id: "tariq_hassan",
      name: "Tariq Hassan",
      state: "Governance",
      biography: "Tariq Hassan is a facilitator and organizational designer who treats meetings as games that should be both fair and fun.\n\nHe has designed decision-making processes for unions, co-ops, and startups, often using cards, random draws, or rotating roles to break up hidden hierarchies. His sessions are noisy, colorful, and surprisingly efficient.\n\nOn the AGATA Senate he proposes voting rituals, rotating committee seats, and citizen assemblies that keep governance alive and legible rather than rigid and intimidating.",
    ),
    Senator(
      id: "blanca_reyes",
      name: "Dr. Blanca Reyes",
      state: "Governance",
      biography: "Blanca Reyes is a historian of land treaties and dispossession in the Southeast, with a focus on how legal documents turned living landscapes into property.\n\nHer fieldwork includes archives, church basements, and front steps where elders remember how land changed hands under pressure. She considers maps and deeds to be both evidence and weapons.\n\nOn the AGATA Senate she insists on acknowledging Indigenous, Black, and tenant histories in every major land and profit decision, embedding reparative practices into the project’s structures rather than leaving them to rhetoric.",
    ),
    Senator(
      id: "sienna_dorsey",
      name: "Sienna Dorsey",
      state: "Governance",
      biography: "Sienna Dorsey came up through open-government campaigns, building simple websites so people could finally see budgets, contracts, and votes that had always been hidden in file cabinets.\n\nShe specializes in turning dense information into dashboards, diagrams, and explainer zines that anyone can understand. Her rule is that no important decision should live only in meeting minutes.\n\nOn the AGATA Senate she designs how decisions, finances, and outcomes are made visible to workers, neighbors, and partners, fighting black-box tendencies wherever they appear.",
    ),
    Senator(
      id: "abdullah_faris",
      name: "Imam Abdullah Faris",
      state: "Governance",
      biography: "Abdullah Faris is a rural imam who has spent years building quiet bridges between farmworkers, churches, and small mosques scattered across back roads.\n\nHe views governance as a moral practice as much as a technical one, drawing on Islamic jurisprudence and community mediation work when conflicts flare. His sermons often revolve around forgiveness, accountability, and shared obligations.\n\nIn the AGATA Senate he acts as a conscience and spiritual check, encouraging the project to hold ethical red lines and to create rituals for repair when it inevitably falls short of its ideals.",
    ),

    // -------------------------------------------------
    // V. Film & Visual Media (Film) 39–48
    // -------------------------------------------------
    Senator(
      id: "delia_moon",
      name: "Delia Moon",
      state: "Film",
      biography: "Delia Moon is a cinematographer obsessed with the way sodium-vapor lights, gas stations, and motels paint the night along rural highways.\n\nShe cut her teeth shooting microbudget music videos and documentary essays about truck stops, learning how to work fast with minimal rigs and crew. Her best work involves long, patient frames of places most people drive past.\n\nOn the AGATA Senate she pushes for shoots that capture Coward’s roadsides, ditches, and parking lots as cinematic spaces, arguing that the visual language of the project should honor what is already there.",
    ),
    Senator(
      id: "arturo_velasquez",
      name: "Arturo Velasquez",
      state: "Film",
      biography: "Arturo Velasquez is a producer who has run multiple indie film shoots through Southern state incentive systems without losing his mind—or his receipts.\n\nHe knows how to hire local crews, document spending, and keep productions both union-friendly and small-town-respectful. His spreadsheets for lodging, per diems, and location fees have become lore among younger producers.\n\nIn the AGATA Senate he helps build a repeatable pipeline to use South Carolina’s incentives for films that actually serve the region, making sure that paperwork and art point in the same direction.",
    ),
    Senator(
      id: "mei_lin",
      name: "Mei Lin",
      state: "Film",
      biography: "Mei Lin is a director known for small, uncanny rural films where science fiction slips quietly into everyday life.\n\nHer early shorts were shot in family grocery stores and abandoned gas stations, blending speculative elements with working-class dramas. She prefers practical effects, long takes, and nonprofessional actors.\n\nOn the AGATA Senate she advocates for films that treat the Pee Dee as a frontier of future stories without erasing its present struggles, nudging the project toward narratives that are weird, generous, and grounded.",
    ),
    Senator(
      id: "quinn_harper",
      name: "Quinn Harper",
      state: "Film",
      biography: "Quinn Harper started as an assistant director and discovered they loved shot lists, maps, and call sheets more than red-carpet moments.\n\nThey developed a planning style that ties each shot to a GPS coordinate, time-of-day note, and weather backup, turning scouting walks into both storyboards and infrastructure surveys. Their notebooks look like cartography experiments.\n\nOn the AGATA Senate Quinn designs shot-listing practices where every film walk doubles as a survey of roads, fences, ditches, and structures, feeding both the art pipeline and the build-out plans.",
    ),
    Senator(
      id: "sofia_pereira",
      name: "Sofia Pereira",
      state: "Film",
      biography: "Sofia Pereira is a documentary photographer who spent years building long-term image archives with fishing communities and factory towns.\n\nShe cares as much about consent, captions, and storage as about composition, often leaving behind prints and small exhibitions before moving on. Her work has helped families and towns see themselves with new respect.\n\nIn the AGATA Senate she helps shape a visual archive that belongs to locals as much as to visiting artists, advocating for shared ownership, careful context, and images that hold dignity even decades later.",
    ),
    Senator(
      id: "jd_holloway",
      name: "J.D. Holloway",
      state: "Film",
      biography: "J.D. Holloway is an editor from rural Kentucky who learned his craft cutting wedding videos, church pageants, and local TV commercials.\n\nOver time he developed a feel for turning uneven footage into coherent, emotionally honest stories, often saving projects that others thought were unusable. His mantra is that nothing is finished until it has been cut for the people who lived it.\n\nOn the AGATA Senate he pushes for post-production discipline, making sure projects actually get edited, captioned, and shared rather than dying as hard drives on a shelf.",
    ),
    Senator(
      id: "zahra_khan",
      name: "Zahra Khan",
      state: "Film",
      biography: "Zahra Khan is a media accessibility specialist who began by volunteering to caption community videos for Deaf friends.\n\nShe has since designed captioning, transcription, and audio-description workflows for podcasts, festivals, and streaming platforms. She treats access features as creative constraints that can add rhythm and poetry.\n\nIn the AGATA Senate she insists that films, streams, and talks be accessible to Deaf, hard-of-hearing, blind, and low-bandwidth audiences, turning accessibility into a defining aesthetic rather than an afterthought.",
    ),
    Senator(
      id: "enzo_mancini",
      name: "Lorenzo \"Enzo\" Mancini",
      state: "Film",
      biography: "Lorenzo Mancini grew up haunting Roman flea markets and later American thrift stores, filling his apartment with odd furniture and stranger props.\n\nHe became a production designer who can dress a set with fifty dollars and a pickup truck, preferring found objects and local textures over rentals. His prop rooms feel like community attics.\n\nOn the AGATA Senate he champions building a prop and costume library that doubles as a community lending closet, making films cheaper while also supporting school plays and neighborhood events.",
    ),
    Senator(
      id: "naima_al_sayeed",
      name: "Naima al-Sayeed",
      state: "Film",
      biography: "Naima al-Sayeed is a documentary filmmaker who became deeply skeptical of how easily cameras can turn people’s pain into content.\n\nHer work centers co-authorship, shared edits, and profit-sharing agreements that give subjects real say over how they appear. She has walked away from festivals that refused to honor these agreements.\n\nIn the AGATA Senate she constantly tests film proposals against questions of consent, power, and benefit, guarding against turning neighbors into subjects instead of collaborators.",
    ),
    Senator(
      id: "cassius_fields",
      name: "Cassius \"Cash\" Fields",
      state: "Film",
      biography: "Cassius Fields spent years as a small-market TV producer in the Carolinas, juggling crime blotters, high school sports, and the occasional human-interest gem.\n\nHe understands exactly what local stations want, what they distort, and how to slip more nuanced stories into thirty-second packages. He also knows how to say no to exploitative coverage.\n\nOn the AGATA Senate he helps pitch AGATA stories to local media in ways that protect residents, build trust, and slowly expand what counts as newsworthy in the region.",
    ),

    // -------------------------------------------------
    // VI. Music & Performance (Music) 49–56
    // -------------------------------------------------
    Senator(
      id: "yasmin_ortiz",
      name: "Yasmin Ortiz",
      state: "Music",
      biography: "Yasmin Ortiz is a producer who specializes in live-off-the-floor recordings in barns, basements, and back porches.\n\nShe made her name cutting records where you can hear trains pass, floors creak, and dogs bark in the distance, treating these sounds as part of the arrangement. Her sessions are fast, warm, and low-stress.\n\nIn the AGATA Senate she designs recording setups that can pop up in any room on the property, helping musicians and visitors walk away with songs that sound like the place they were made.",
    ),
    Senator(
      id: "brother_eli_thompson",
      name: "Brother Eli Thompson",
      state: "Music",
      biography: "Brother Eli Thompson is a Pentecostal choirleader whose life has been spent in church basements, tent revivals, and potluck lines across South Carolina.\n\nHe is steeped in gospel, shape-note singing, and the social worlds that form around choir practice. His choirs are intergenerational and rarely stick to the program.\n\nOn the AGATA Senate he bridges church traditions and experimental ensembles, advocating for regular public song circles and services that welcome locals and residents under the same roof.",
    ),
    Senator(
      id: "kaito_nakamura",
      name: "Kaito Nakamura",
      state: "Music",
      biography: "Kaito Nakamura is a builder of hacked instruments and contact-mic sculptures who grew up in Osaka disassembling radios.\n\nHe moved between noise scenes, maker spaces, and small farms, learning how to turn scrap metal, wire fences, and water tanks into playable objects. Performances with his instruments often look like maintenance rituals.\n\nIn the AGATA Senate he anchors the overlap between the music scene and the hardware lab, arguing for a yard of sonic experiments built from the farm’s own material leftovers.",
    ),
    Senator(
      id: "laila_khatri",
      name: "Laila Khatri",
      state: "Music",
      biography: "Laila Khatri is a festival programmer who took over a struggling urban arts festival and turned it into a beloved, small-scale institution.\n\nShe excels at building lineups that pair experimental acts with approachable crowd-pleasers, and at crafting flows across a weekend so introverts and families can find their moments. Her budgets always include quiet spaces and childcare.\n\nOn the AGATA Senate she helps design seasonal festivals that feel like both neighborhood gatherings and invitations to artistic risk, carefully managing scale so the land and locals are not overwhelmed.",
    ),
    Senator(
      id: "duke_jennings",
      name: "Duke \"Railroad\" Jennings",
      state: "Music",
      biography: "Duke Jennings is a bar-band veteran with an encyclopedic knowledge of jukebox country and honky-tonk ballads.\n\nHe has played every kind of dive from Mississippi to Missouri, watching which songs clear a room and which ones make strangers dance together. His stage banter is half oral history lesson, half comedy.\n\nIn the AGATA Senate he keeps at least one foot of the music program in familiar territory, arguing for Saturday night barn dances and sets that local elders and teens can share.",
    ),
    Senator(
      id: "nandi_okeke",
      name: "Nandi Okeke",
      state: "Music",
      biography: "Nandi Okeke is a choreographer who stages performance pieces in factories, kitchens, and subway platforms, treating work as a kind of dance.\n\nHer projects often start by watching how people already move, then building scores that highlight those motions without turning workers into props. She has collaborated with unions, museums, and cleaning crews.\n\nOn the AGATA Senate she pushes for performances that center the rhythms of farm and care labor, inviting workers themselves to design how their bodies appear in the project’s art.",
    ),
    Senator(
      id: "clara_vogt",
      name: "Clara Vogt",
      state: "Music",
      biography: "Clara Vogt is a sound artist who composes by walking, recording, and layering the ordinary noises of streets, creeks, and backyards.\n\nHer soundwalks guide participants through routes where listening reshapes how they see gutters, fences, and power lines. Some of her albums consist entirely of footsteps, birds, and distant trains.\n\nIn the AGATA Senate she designs listening routes across fields, ditches, and woods, making sound a way to teach ecology, infrastructure, and memory all at once.",
    ),
    Senator(
      id: "sergio_alvarez",
      name: "Sergio Alvarez",
      state: "Music",
      biography: "Sergio Alvarez is a former public-school band director who scraped together instruments and repaired dented horns so every kid who wanted to play could.\n\nHe ran after-school ensembles that mixed marching tunes with cumbia, hip-hop, and gospel, quietly mentoring students who had nowhere else to go between 3 and 6 p.m. Many of his alumni still text him before big life decisions.\n\nOn the AGATA Senate he champions youth music programs with real gear, practice space, and recording opportunities, arguing that any rural arts utopia must have a messy, joyful youth band at its core.",
    ),

    // -------------------------------------------------
    // VII. Digital Product, AI & Data (Digital) 57–66
    // -------------------------------------------------
    Senator(
      id: "helena_suarez",
      name: "Dr. Helena Suarez",
      state: "Digital",
      biography: "Helena Suarez is a computer scientist who left a well-funded Silicon Valley agtech startup after watching dashboards no farmer she met actually used.\n\nShe began consulting directly with small farms, co-designing tiny tools that fit their notebooks, not investors’ slide decks. Her favorite projects are those that quietly disappear into ordinary routines.\n\nOn the AGATA Senate she acts as translator between code and field, insisting that any AI or software be requested, understandable, and maintainable by the people who will rely on it during a heat wave.",
    ),
    Senator(
      id: "jamal_rivers",
      name: "Jamal Rivers",
      state: "Digital",
      biography: "Jamal Rivers grew up in a Mississippi town where cracked phone screens and slow data plans were the norm, not the exception.\n\nHe became a UX designer focused on low-bandwidth, low-literacy interfaces—big buttons, clear language, offline-first patterns. His early work for a rural clinic system drastically cut missed appointments.\n\nIn the AGATA Senate he designs digital touchpoints for cracked screens and tired eyes, reminding everyone that a beautiful interface is useless if it assumes perfect devices and attention.",
    ),
    Senator(
      id: "petra_novak",
      name: "Dr. Petra Novak",
      state: "Digital",
      biography: "Petra Novak is a statistician who grew deeply uneasy with the mantra that more data is always better.\n\nHer career shifted from building predictive models for corporations to helping community groups decide what not to measure. She emphasizes clear questions, small datasets, and careful interpretation.\n\nOn the AGATA Senate she argues for data minimalism, limiting what is collected about workers and visitors and focusing instead on a few meaningful indicators of soil health, financial stability, and well-being.",
    ),
    Senator(
      id: "khadija_ali",
      name: "Khadija Ali",
      state: "Digital",
      biography: "Khadija Ali is an engineer who worked on bias mitigation and interpretability for large AI systems before burning out on corporate ethics theater.\n\nShe now helps cooperatives and nonprofits design AI workflows where humans stay firmly in charge and can see how decisions are made. Her trainings demystify jargon and empower people to say no.\n\nIn the AGATA Senate she helps design the Harmony-like AI governance stack so that it remains accountable, legible, and clearly subordinate to the workers and neighbors it serves.",
    ),
    Senator(
      id: "rowan_flynn",
      name: "Rowan Flynn",
      state: "Digital",
      biography: "Rowan Flynn is an open-source maintainer who has spent years patching underfunded libraries on their laptop at odd hours.\n\nThey know how licensing, governance, and burnout interact, and they have walked away from projects that refused to share power or credit. Their happiest moments come when a new contributor ships their first fix.\n\nOn the AGATA Senate Rowan guides software projects toward licenses and structures that share power and encourage contributions without overburdening a few heroes.",
    ),
    Senator(
      id: "marta_zielinska",
      name: "Marta Zielinska",
      state: "Digital",
      biography: "Marta Zielinska is a data visualization artist who started by drawing hand-made charts for neighbors’ utility bills and school budgets.\n\nShe later worked with cities and co-ops, turning complicated numbers into posters, dashboards, and coloring books people could actually use. Her favorite charts can be taped to a fridge or barn wall.\n\nIn the AGATA Senate she designs visualizations of soil health, labor fairness, and creative output that make progress and problems visible at a glance.",
    ),
    Senator(
      id: "devon_blake",
      name: "Devon Blake",
      state: "Digital",
      biography: "Devon Blake is a systems engineer who fell in love with software that keeps working when the network dies and the lights flicker.\n\nThey have built offline-first apps for clinics, libraries, and disaster-response teams, always pairing digital tools with paper and radio backups. For Devon, resilience matters more than elegance.\n\nOn the AGATA Senate they push for local-first software, sync queues, and simple failovers so storms and outages become inconveniences, not existential threats.",
    ),
    Senator(
      id: "zainab_yusuf",
      name: "Zainab Yusuf",
      state: "Digital",
      biography: "Zainab Yusuf is a developer who specializes in digital preservation: formats, checksums, migration plans, and the human habits that make archives survive.\n\nShe has helped community organizations rescue collections from obsolete drives and platforms, building systems that work with both elders’ shoeboxes and cloud drives. She thinks in decades.\n\nOn the AGATA Senate she designs the long-term digital archive for films, texts, and sensor data, making sure today’s work can still be read and remixed by people who have never heard of current file formats.",
    ),
    Senator(
      id: "hugo_laurent",
      name: "Hugo Laurent",
      state: "Digital",
      biography: "Hugo Laurent is an orchestration engineer who loves multi-agent systems as long as their decision-making can be inspected and reasoned about.\n\nHe has built agent frameworks for research labs and cooperatives, always insisting on logs, diaries, and human-friendly summaries. His tools make it easy to ask, \"Why did the system choose that?\" and get a real answer.\n\nIn the AGATA Senate he helps structure the Harmony-style Senate and its sub-agents so that their advice can be audited, compared, and improved over time rather than treated as mysterious oracles.",
    ),
    Senator(
      id: "riley_shaw",
      name: "Riley Shaw",
      state: "Digital",
      biography: "Riley Shaw is a civic technologist who has built tools for city councils, mutual-aid groups, and neighborhood associations.\n\nTheir favorite projects are simple: text-message hotlines, public notice boards, and searchable meeting notes that let people actually participate. They avoid building systems that rely on one tech-savvy volunteer.\n\nOn the AGATA Senate Riley looks for ways to connect AGATA’s digital tools to county processes, schools, and local nonprofits so the project feels like part of a wider civic fabric, not a tech island.",
    ),

    // -------------------------------------------------
    // VIII. Mesh Networking & Hardware (Mesh) 67–72
    // -------------------------------------------------
    Senator(
      id: "anika_sorensen",
      name: "Anika Sørensen",
      state: "Mesh",
      biography: "Anika Sørensen is a network engineer who cut her teeth setting up mesh systems in remote Scandinavian fishing villages and windswept farms.\n\nShe is less interested in speed tests than in graceful degradation—what still works when one node dies, when the backhaul fails, when the power blinks. Her favorite diagrams show lines of failure and backup.\n\nOn the AGATA Senate she maps a mesh of nodes on barns, houses, and trees, designing a network that neighbors can help maintain with a ladder and a wrench.",
    ),
    Senator(
      id: "malik_al_karim",
      name: "Malik al-Karim",
      state: "Mesh",
      biography: "Malik al-Karim spent his twenties running a strip-mall phone and electronics repair shop, learning how people actually break and fix their devices.\n\nHe has seen every cracked screen, blown capacitor, and cable kludge that walks in off the street, and he enjoys explaining repairs slowly enough that customers can try them next time. Later he began teaching repair workshops.\n\nIn the AGATA Senate he argues for a small on-site electronics lab and clear repair manuals with photos, making the mesh network and studio gear fixable by locals instead of shipping everything to distant service centers.",
    ),
    Senator(
      id: "janelle_brooks",
      name: "Janelle Brooks",
      state: "Mesh",
      biography: "Janelle Brooks is a solar installer who has spent years climbing roofs and crawling into attics in both cities and hollers.\n\nShe specializes in off-grid and microgrid systems for small farms, churches, and community centers, learning to respect both shade patterns and gossip networks. Her designs consider who will actually flip which breaker during a storm.\n\nOn the AGATA Senate she plans solar arrays, batteries, and wiring so that wells, fridges, studios, and common spaces have layered power redundancy without becoming fragile showpieces.",
    ),
    Senator(
      id: "viktor_ilyin",
      name: "Dr. Viktor Ilyin",
      state: "Mesh",
      biography: "Viktor Ilyin is an engineer who loves cheap sensors, homebrew weather stations, and the satisfying click of a well-wired relay.\n\nHe has worked on environmental monitoring systems for farms and cities, always trying to keep hardware simple enough that non-engineers can swap parts. He is suspicious of sensor networks that become surveillance nets.\n\nOn the AGATA Senate he designs environmental sensing—soil moisture, rain, temperature, structural stress—while drawing firm lines against tracking people’s movements and conversations.",
    ),
    Senator(
      id: "penny_griggs",
      name: "Penelope \"Penny\" Griggs",
      state: "Mesh",
      biography: "Penny Griggs runs a tool library in a mid-sized city where contractors and hobbyists share saws, drills, and sanders instead of buying everything new.\n\nShe is fluent in barcodes, label makers, and the psychology of late returns, and she has seen how access to tools changes what people dare to build. Her workshops often mix safety briefings with creative challenges.\n\nOn the AGATA Senate she helps design a shared library of farm, film, and fabrication tools with simple check-out systems, making it easier for residents and neighbors to try projects without huge upfront costs.",
    ),
    Senator(
      id: "imani_zulu",
      name: "Imani Zulu",
      state: "Mesh",
      biography: "Imani Zulu is a community-radio enthusiast who grew up falling asleep to crackling night broadcasts that stitched rural counties together.\n\nShe has helped launch low-power FM stations and online streams that blend music, local news, and emergency alerts. For her, a small station is both an information hub and a storytelling engine.\n\nIn the AGATA Senate she advocates for a Pee Dee-focused broadcast from the farm—part arts show, part weather and road report—so the project can talk with its neighbors, not just about them.",
    ),

    // -------------------------------------------------
    // IX. Education, Youth & Pedagogy (Education) 73–78
    // -------------------------------------------------
    Senator(
      id: "margaret_shaw",
      name: "Dr. Margaret \"Maggie\" Shaw",
      state: "Education",
      biography: "Maggie Shaw ran a farm-based high school program where math problems involved real fence lines and biology labs happened in muddy fields.\n\nShe has watched students who floundered in classrooms suddenly come alive when asked to design irrigation or calculate feed ratios. Her courses rely on portfolios and presentations rather than standardized tests.\n\nOn the AGATA Senate she helps design seasonal curricula for youth, residents, and workers, turning everyday tasks into learning modules that could one day connect to credits or certificates.",
    ),
    Senator(
      id: "jamila_rhodes",
      name: "Jamila Rhodes",
      state: "Education",
      biography: "Jamila Rhodes is a youth organizer who learned early that most councils and boards love to talk about youth but rarely share power with them.\n\nShe has helped create youth councils with real budgets in small towns and city neighborhoods, training teenagers in facilitation, budgeting, and gentle stubbornness. Her graduates now sit on school boards and co-op committees.\n\nIn the AGATA Senate she pushes for a formal Youth Council with decision-making power and resources, making sure young people are neither tokenized nor ignored.",
    ),
    Senator(
      id: "antonio_rivera",
      name: "Mr. Antonio Rivera",
      state: "Education",
      biography: "Antonio Rivera is a retired shop teacher who taught welding, carpentry, and basic mechanics in a district that kept trying to cut his program.\n\nHe spent decades turning donated scrap into teaching material and nervous teens into competent builders. Safety, self-respect, and the satisfaction of making something that works were his core curriculum.\n\nOn the AGATA Senate he designs beginner-friendly skill tracks, safety protocols, and apprenticeship paths so residents and neighbors can learn to fix and build the infrastructure around them.",
    ),
    Senator(
      id: "hyojin_lee",
      name: "Dr. Hyojin Lee",
      state: "Education",
      biography: "Hyojin Lee is an educator who studied liberatory pedagogy and then tested it in after-school programs, prisons, and community colleges.\n\nShe excels at turning real projects—like starting a garden or launching a co-op—into structured learning experiences with clear steps and reflections. Her courses often end with public showcases rather than exams.\n\nOn the AGATA Senate she helps translate the project’s activities into modules—compost 101, co-op economics 102, night ecology 201—that can serve locals and visiting students alike.",
    ),
    Senator(
      id: "sarah_ann_mcleod",
      name: "Sarah Ann McLeod",
      state: "Education",
      biography: "Sarah Ann McLeod is a literacy advocate who sets up reading nooks wherever people naturally wait: bus stops, laundromats, clinic lobbies.\n\nShe has stocked tiny libraries with zines, how-to guides, and local history pamphlets, often written by residents themselves. Her work blurs the line between publishing and organizing.\n\nIn the AGATA Senate she champions porches, barns, and corners of the house as reading and storytelling zones, filled with work from AGATA participants and Pee Dee writers.",
    ),
    Senator(
      id: "kofi_mensah",
      name: "Kofi Mensah",
      state: "Education",
      biography: "Kofi Mensah is a program manager who has spent years arranging exchanges between rural and urban youth, farmers and coders, elders and students.\n\nHe cares less about flashy photos and more about long-term reciprocity, designing visits where both sides teach and learn. Many of his programs include second and third visits years later.\n\nOn the AGATA Senate he helps host visiting groups and send locals elsewhere, weaving the project into wider networks without turning it into a tourist attraction.",
    ),

    // -------------------------------------------------
    // X. History, Memory & Archives (History) 79–84
    // -------------------------------------------------
    Senator(
      id: "althea_brooks",
      name: "Dr. Althea Brooks",
      state: "History",
      biography: "Althea Brooks is a historian of the Pee Dee region, making her career out of factory payrolls, church bulletins, and family collections that universities once ignored.\n\nShe focuses on agricultural change, industrialization, and civil-rights organizing, often following the same surnames across generations and job sites. Her tours mix dates with gossip and sensory detail.\n\nOn the AGATA Senate she keeps plans grounded in what has already been tried, won, and lost in the area, pushing for oral-history projects and collaborations with elders who hold crucial stories.",
    ),
    Senator(
      id: "darnell_watson",
      name: "Darnell Watson",
      state: "History",
      biography: "Darnell Watson is a self-taught genealogist whose hobby of tracing his own family tree turned into a vocation helping others reconnect with scattered relatives.\n\nHe has spent countless weekends photographing headstones, scanning Bibles, and decoding nicknames in obituaries. His maps show how families stretch across counties and states.\n\nIn the AGATA Senate he advises on family archives, cemetery care, and reunion partnerships, helping the project situate present-day workers and neighbors within deeper lineages.",
    ),
    Senator(
      id: "chiara_santori",
      name: "Dr. Chiara Santori",
      state: "History",
      biography: "Chiara Santori is a scholar of historical utopian communities, from New Harmony and Oneida to lesser-known Southern experiments.\n\nShe is as interested in why they failed as in what they built, studying governance, gender roles, land tenure, and conflict handling. Her work is full of marginal notes like \"this sounded great until it met laundry.\" \n\nOn the AGATA Senate she brings cautionary tales and design patterns, helping avoid classic utopian errors like overwork, secrecy, and charismatic unaccountable leaders.",
    ),
    Senator(
      id: "latasha_byrd",
      name: "Latasha \"Tasha\" Byrd",
      state: "History",
      biography: "Latasha Byrd is a community archivist who started by organizing her grandmother’s shoeboxes of photos and grew into coordinating neighborhood history projects.\n\nShe prefers living rooms and church halls to formal reading rooms, teaching people how to label, scan, and share their own materials. Her projects often end with pop-up exhibits in barber shops and corner stores.\n\nOn the AGATA Senate she designs collaborative archives where locals keep control of their images and stories, and where the line between AGATA’s history and the region’s history remains porous.",
    ),
    Senator(
      id: "henrik_olsen",
      name: "Dr. Henrik Olsen",
      state: "History",
      biography: "Henrik Olsen is a historian of infrastructure: roads, rails, power lines, and telecoms that quietly rearranged economies and ecologies.\n\nHe has traced how decisions about highways and industrial parks in the South shaped which towns thrived, which faded, and who bore pollution. His field trips often involve standing under overpasses.\n\nIn the AGATA Senate he reads build-out plans against these longer histories, spotting chances to leverage existing networks or deliberately step aside from harmful patterns.",
    ),
    Senator(
      id: "mildred_gaines",
      name: "Reverend Dr. Mildred Gaines",
      state: "History",
      biography: "Mildred Gaines is a theologian and pastor who studies how communities remember through ritual, food, and song more than through monuments.\n\nShe has worked with congregations to design services and annual observances that hold both joy and grief, especially around factory closures, floods, and violent events. Her cooking often doubles as liturgy.\n\nOn the AGATA Senate she encourages the creation of yearly days of remembrance and thanks, designing embodied practices that keep the project’s origins and obligations visible.",
    ),

    // -------------------------------------------------
    // XI. Ritual, Festivals & Spiritual Ecology (Ritual) 85–90
    // -------------------------------------------------
    Senator(
      id: "saffron_patel",
      name: "Saffron Patel",
      state: "Ritual",
      biography: "Saffron Patel is a festival designer who maps the calendar as a wheel of moods, energies, and agricultural tasks rather than as a list of dates.\n\nShe has helped communities build seasonal cycles of gatherings that include quiet workshops, raucous celebrations, and reflective vigils, all timed to local weather and school schedules. Her cue cards often reference phases of the moon as much as grant deadlines.\n\nOn the AGATA Senate she helps craft a year of festivals and rituals tied to planting, harvest, storms, and rest, giving the project a shared heartbeat.",
    ),
    Senator(
      id: "ezekiel_harper",
      name: "Ezekiel \"Zeke\" Harper",
      state: "Ritual",
      biography: "Zeke Harper is a skilled fire tender who has overseen bonfires for everything from protest camps to scout jamborees.\n\nHe knows how to build, site, and supervise flames that feel safe but still powerful, and he treats the act of lighting and extinguishing as a ceremony. He insists on water buckets, clear paths, and sober fire keepers.\n\nIn the AGATA Senate he designs bonfire rituals for storytelling, conflict resolution, and celebration, working closely with ecologists and safety planners so fire becomes a wise ally, not a hazard.",
    ),
    Senator(
      id: "amina_rahman",
      name: "Dr. Amina Rahman",
      state: "Ritual",
      biography: "Amina Rahman is a psychologist and ritual designer who works with climate grief, rural loss, and the emotions people are told to swallow to keep going.\n\nShe has facilitated circles for farmers after droughts, coal families after mine closures, and students after hurricanes, blending therapeutic tools with culturally grounded practices. Her sessions often involve objects, songs, and simple shared meals.\n\nOn the AGATA Senate she advocates for spaces and times devoted to grief and transition, making room for mourning without letting it paralyze the project.",
    ),
    Senator(
      id: "willow_james",
      name: "Willow James",
      state: "Ritual",
      biography: "Willow James is an artist who runs collective dream mapping workshops, asking people to draw and narrate the landscapes of their sleep.\n\nThey have worked with neighborhoods, shelters, and co-ops, finding recurring symbols that often prefigure conflicts or opportunities. Their dream maps look like strange, overlapping city plans.\n\nIn the AGATA Senate Willow invites workers, neighbors, and residents to bring dreams, nightmares, and recurring images into the planning process, offering a way to surface unconscious hopes and fears.",
    ),
    Senator(
      id: "mateo_cruz",
      name: "Brother Mateo Cruz",
      state: "Ritual",
      biography: "Brother Mateo Cruz is a monk-turned-walking-guide who has led pilgrimages through industrial zones, forests, and along drainage canals.\n\nHe designs routes that mix hard surfaces and soft ground, noise and quiet, always ending at a place of rest or shared food. For him, pilgrimage is about paying attention to what we usually hurry past.\n\nOn the AGATA Senate he helps frame some visits as pilgrimages, with marked paths, small shrines, and rest stops that invite reflection on land, work, and community.",
    ),
    Senator(
      id: "rani_singh",
      name: "Rani Singh",
      state: "Ritual",
      biography: "Rani Singh is a chef who treats shared meals as rituals that can open, close, or transform a group’s work together.\n\nShe has cooked for protest kitchens, silent retreats, and neighborhood block parties, crafting menus that tell stories about seasons, migrations, and labor. Her feasts often include a moment of naming everyone who helped make them possible.\n\nIn the AGATA Senate she designs seasonal feasts and everyday kitchen habits that root the project’s values in pots, plates, and recipes, not just in documents.",
    ),

    // -------------------------------------------------
    // XII. Lived-Experience Reps (Community) 91–100
    // -------------------------------------------------
    Senator(
      id: "curtis_johnson",
      name: "Curtis \"Slim\" Johnson",
      state: "Community",
      biography: "Curtis Johnson spent most of his adult life on textile mill floors, working swing shifts that left his body aching and his sleep permanently odd.\n\nHe has seen machines speed up, wages stagnate, and eventually gates close for good. Yet he still takes pride in the precision and skill his work required, and he bristles when people talk about \"unskilled\" labor.\n\nOn the AGATA Senate he speaks bluntly about paychecks, fatigue, and respect, making sure that talk of \"good jobs\" is measured against lived experience, not slogans.",
    ),
    Senator(
      id: "maria_santos",
      name: "Maria Santos",
      state: "Community",
      biography: "Maria Santos has spent years as a migrant farmworker and mother, moving with the seasons and wrestling with housing, childcare, and fear of sudden raids.\n\nShe has packed lettuce, picked berries, and cleaned motels, always scanning for which towns felt safer and which employers kept their promises. Her stories rarely appear in official reports.\n\nIn the AGATA Senate she brings the perspective of migrant families, pressing for housing, legal support, and governance structures that make seasonal and undocumented workers visible stakeholders rather than ghost labor.",
    ),
    Senator(
      id: "geraldine_white",
      name: "Miss Geraldine \"Geri\" White",
      state: "Community",
      biography: "Geraldine White has lived near Coward her entire life and can tell you who used to own which field, which cousin married whom, and where the creek flooded in '73.\n\nHer porch has been a quiet counseling office for neighbors navigating divorces, debts, and church disputes. She keeps a mental map of who trusts whom and why.\n\nOn the AGATA Senate she reads the social landscape, warning when plans will stir old wounds or surprising alliances, and reminding everyone that history lives in people’s feelings as much as in archives.",
    ),
    Senator(
      id: "tyrell_brooks",
      name: "Tyrell Brooks",
      state: "Community",
      biography: "Tyrell Brooks is a high school student who spends most of his free time riding a BMX bike along back roads, vacant lots, and drainage ditches.\n\nHe knows every unofficial hangout, shortcut, and sketchy intersection in a thirty-mile radius. To him, a project like AGATA is both an opportunity and a possible intrusion.\n\nIn the AGATA Senate he speaks for local youth who want spots to skate, play, and be left alone as much as they want jobs or programs, pushing designs that make teens feel welcome rather than policed.",
    ),
    Senator(
      id: "shonda_miller",
      name: "Shonda Miller",
      state: "Community",
      biography: "Shonda Miller works nights as a certified nursing assistant at a nearby facility, juggling patient care, family obligations, and chronic exhaustion.\n\nShe has seen how low pay and thin staffing stretch workers beyond reason, and how fragile patients and families become when care systems fail. Her rare days off are precious.\n\nOn the AGATA Senate she brings the realities of care workers into view, asking how the project can support local caregivers with respite, space, and maybe even better jobs without simply extracting more of their energy.",
    ),
    Senator(
      id: "deandre_hill",
      name: "DeAndre \"Dre\" Hill",
      state: "Community",
      biography: "DeAndre Hill lives on land that shares a fence line with the AGATA property, and he hears every truck, sees every light, and smells every burn pile.\n\nHe works construction jobs around the county and pays close attention to how new projects change traffic, noise, and property values for neighbors. He has seen both empty promises and rare good-faith efforts.\n\nIn the AGATA Senate he represents the literal next-door stakes, reminding everyone that for some people the project is not a destination but a constant presence over the fence.",
    ),
    Senator(
      id: "lupe_garcia",
      name: "Lupe García",
      state: "Community",
      biography: "Lupe García works long shifts as a clerk at a gas station–mini-mart near Coward, standing at a crossroads of gossip, commerce, and quiet desperation.\n\nShe sees who comes through hungry, who is on the road for work, who pays in coins, and which snack displays actually move. Her sense of the local economy is visceral and daily.\n\nOn the AGATA Senate she brings granular knowledge of what people buy, talk about, and worry over, helping shape farm-stand offerings, café menus, and outreach in ways that meet real desires.",
    ),
    Senator(
      id: "auntie_joyce_patterson",
      name: "Auntie Joyce Patterson",
      state: "Community",
      biography: "Auntie Joyce Patterson runs the kitchen at a nearby church and is the unofficial social worker for many families in the area.\n\nShe coordinates funeral repasts, baby showers, and emergency food deliveries with equal grace, often out of her own pantry. People tell her things they won’t tell their doctors or bosses.\n\nIn the AGATA Senate she bridges the project with church and family networks, offering both practical feedback on food and schedules and deeper insight into who needs support but may never show up to a meeting.",
    ),
    Senator(
      id: "malikah_johnson",
      name: "Malikah \"Mali\" Johnson",
      state: "Community",
      biography: "Malikah Johnson is a community-college student studying IT while working part time at a call center, trying to carve out time to learn coding and media production.\n\nShe feels the tug between wanting to stay close to family and wanting to chase opportunities elsewhere, and she knows how quickly limited transportation and childcare can choke off ambition.\n\nOn the AGATA Senate she advocates for labs and studios that are truly accessible to local youth and working adults, with hours, equipment, and support that make experimentation possible.",
    ),
    Senator(
      id: "empty_chair",
      name: "The Empty Chair",
      state: "Community",
      biography: "The Empty Chair is a deliberately reserved seat in the AGATA Senate, holding space for a voice the project has not yet recognized that it needs.\n\nIt may one day belong to a local tribal representative, a disabled neighbor, an incarcerated organizer, a future worker, or another group whose absence would otherwise remain invisible. For now, it remains a reminder that the roster is not complete.\n\nIn every major decision the AGATA Senate is asked to imagine who might someday sit in the Empty Chair and how that person would judge the choice, keeping humility and openness built into the chamber’s structure.",
    ),
  ]
}

pub fn all() -> List(Senator) {
  all_senators()
}
// pub fn all_senators() -> List(Senator) {
//   [
//     Senator(
//       id: "katie_britt",
//       name: "Katie Britt",
//       state: "Alabama",
//       biography: "Katie Britt was born in Enterprise, Alabama and grew up helping her parents run a small construction firm before heading to cheer practice or 4-H meetings.\n\nShe studied at the University of Alabama for both undergraduate and law degrees and built a career as a congressional aide who became chief of staff to Senator Richard Shelby and later president of the Business Council of Alabama. Those roles put her in the middle of port dredging talks, hurricane recovery plans, and apprenticeship expansions across the Gulf Coast.\n\nElected in 2022 as Alabama's first female senator, she now focuses on workforce training, coastal infrastructure, and maternal health clinics, often citing long drives between Wiregrass towns to explain the stakes.",
//     ),
//     Senator(
//       id: "tommy_tuberville",
//       name: "Tommy Tuberville",
//       state: "Alabama",
//       biography: "Tommy Tuberville was born in Camden, Arkansas and spent his childhood bouncing between military towns before settling in the South, where football fields became his second home.\n\nHe studied at Southern Arkansas University and built a career as a high-school coach turned collegiate head coach who led Ole Miss and Auburn and later hosted leadership camps and charity tournaments across Alabama. Decades on the sideline taught him to recruit talent, manage staffs, and navigate booster politics.\n\nWinning a Senate seat in 2020, he now draws on that playbook when pressing for agricultural research, military housing upgrades, and a national framework for college athlete compensation.",
//     ),
//     Senator(
//       id: "lisa_murkowski",
//       name: "Lisa Murkowski",
//       state: "Alaska",
//       biography: "Lisa Murkowski was born in Ketchikan, Alaska and was raised in small fishing towns along the Inside Passage, where floatplanes doubled as school buses and winter storms directed grocery runs.\n\nShe studied at Georgetown University and Willamette University College of Law and built a career as worked as an Anchorage attorney and served in the Alaska House, focusing on land-use and rural energy policy. She honed bipartisan skills chairing the state House Labor and Commerce Committee.\n\nAppointed in 2002 and famous for her 2010 write-in victory, Murkowski champions Arctic research, Coast Guard infrastructure, and reproductive healthcare access.",
//     ),
//     Senator(
//       id: "dan_sullivan",
//       name: "Dan Sullivan",
//       state: "Alaska",
//       biography: "Dan Sullivan was born in Fairview Park, Ohio and spent summers fishing the Kenai before moving north full time, blending Midwestern roots with Alaska's frontier ethic.\n\nHe studied at Harvard University and Georgetown University Law Center and built a career as served as a Marine Corps officer, clerked on the D.C. Circuit, and held national security posts before becoming Alaska's attorney general and commissioner of natural resources. He led multistate fights over the Endangered Species Act and offshore development.\n\nElected in 2014, Sullivan focuses on Arctic shipping lanes, defense modernization, and veterans mental health, often drilling with his Marine reserve unit on weekends.",
//     ),
//     Senator(
//       id: "ruben_gallego",
//       name: "Ruben Gallego",
//       state: "Arizona",
//       biography: "Ruben Gallego was born in Chicago to immigrant parents from Colombia and Mexico and was the first in his family to graduate from college.\n\nHe studied at Harvard University and served as a Marine Corps infantryman in Iraq before being elected to the Arizona House, where he pushed veteran mental health services and early investments in broadband. Later, as a U.S. Representative from Phoenix, he became known for oversight of VA waitlists and for advocating Indigenous water rights and border modernisation.\n\nElected to the Senate in 2024, Gallego focuses on veteran care, semiconductor supply chains anchored in Arizona, and pragmatic border security that pairs technology with legal pathway reforms.",
//     ),
//     Senator(
//       id: "mark_kelly",
//       name: "Mark Kelly",
//       state: "Arizona",
//       biography: "Mark Kelly was born in West Orange, New Jersey and was raised by two police officers who encouraged him and his twin brother to explore tinkering projects in the family garage.\n\nHe studied at the U.S. Merchant Marine Academy and later the U.S. Naval Postgraduate School and built a career as a Navy combat pilot who flew 39 combat missions during Operation Desert Storm before becoming a NASA astronaut and commanding two shuttle missions. After his wife Gabby Giffords survived a 2011 assassination attempt, he co-founded an organization focused on ending gun violence.\n\nKelly won a special election in 2020 and a full term in 2022, bringing astronaut-style checklists to debates on water security, semiconductor manufacturing, and support for military families stationed at Arizona bases.",
//     ),
//     Senator(
//       id: "john_boozman",
//       name: "John Boozman",
//       state: "Arkansas",
//       biography: "John Boozman was born in Shreveport, Louisiana and moved with his Air Force family to Fort Smith, Arkansas, where he balanced 4-H judging with helping on the family farm.\n\nHe studied at the University of Arkansas and the Southern College of Optometry and built a career as an optometrist who co-founded a clinic in Rogers before serving on the school board and running large-scale vision programs for low-income kids. His medical practice introduced him to veterans and poultry workers facing preventable blindness, which influenced his later legislation.\n\nAfter a decade in the U.S. House he entered the Senate in 2011, focusing on veterans rehabilitation, agricultural research, and navigation upgrades along the McClellan–Kerr Arkansas River system.",
//     ),
//     Senator(
//       id: "tom_cotton",
//       name: "Tom Cotton",
//       state: "Arkansas",
//       biography: "Tom Cotton was born in Dardanelle, Arkansas and grew up on his family's cattle farm in Yell County, where long days of baling hay instilled a respect for rural grit.\n\nHe studied at Harvard College and Harvard Law School and built a career as an Army infantry officer who deployed to Iraq and Afghanistan before clerking for a federal judge and practicing law. His 2006 letter challenging the New York Times over classified information thrust him into the national security debate.\n\nElected to the Senate in 2014 after one term in the House, Cotton is a leading voice on defense, intelligence, and supply-chain resilience, often referencing Ranger School lessons on preparation.",
//     ),
//     Senator(
//       id: "adam_schiff",
//       name: "Adam Schiff",
//       state: "California",
//       biography: "Adam Schiff was born in Framingham, Massachusetts and moved to California as a child, where he blended academics with debate club and student government.\n\nHe studied at Stanford University and Harvard Law School and served as an Assistant U.S. Attorney before winning seats in the California Senate and later the U.S. House, chairing the House Intelligence Committee. His work spanned national security oversight, wildfire recovery funding, and water resilience for Southern California.\n\nElected to the Senate in 2024, Schiff focuses on technology competition, clean energy transmission, and protecting democratic institutions against foreign interference.",
//     ),
//     Senator(
//       id: "alex_padilla",
//       name: "Alex Padilla",
//       state: "California",
//       biography: "Alex Padilla was born in Los Angeles, California and is the son of Mexican immigrants who worked as a short-order cook and a housekeeper, and he often translated paperwork for neighbors in Pacoima.\n\nHe studied at the Massachusetts Institute of Technology, where he studied mechanical engineering and built a career as a Los Angeles city councilmember who later served in the California Senate and as California's secretary of state, modernizing election technology and automatic voter registration. Padilla's engineering mindset led him to focus on seismic upgrades to water and rail systems.\n\nAppointed in 2021 and elected the following year, he now champions immigration reform, wildfire resilience, and STEM education pipelines for students from working-class families like his own.",
//     ),
//     Senator(
//       id: "michael_bennet",
//       name: "Michael Bennet",
//       state: "Colorado",
//       biography: "Michael Bennet was born in New Delhi, India and grew up in Washington, D.C., where his diplomat father served successive presidents and exposed him to public service debates at the dinner table.\n\nHe studied at Wesleyan University and Yale Law School and built a career as a corporate lawyer who became chief of staff to Denver Mayor John Hickenlooper before running the Denver Public Schools, where he pushed innovative financing to renovate aging buildings. His school turnaround work inspired the early-childhood provisions later embedded in federal policy.\n\nAppointed to the Senate in 2009 and subsequently elected, Bennet focuses on child tax credits, wildfire mitigation, and bipartisan immigration fixes, often referencing both classroom visits and Western water tours.",
//     ),
//     Senator(
//       id: "john_hickenlooper",
//       name: "John Hickenlooper",
//       state: "Colorado",
//       biography: "John Hickenlooper was born in Narberth, Pennsylvania and was raised by a widowed mother who taught him thrift and curiosity, habits he fed by collecting rocks and running science experiments in the basement.\n\nHe studied at Wesleyan University and the Colorado School of Mines for post-graduate geology coursework and built a career as a petroleum geologist who co-founded Denver's first brewpub after a layoff, sparking the revitalization of LoDo and later serving as Denver mayor and Colorado governor. His entrepreneurial streak led to transit expansions, creative arts districts, and statewide broadband mapping.\n\nElected to the Senate in 2020, Hickenlooper now brings that operator's mindset to work on infrastructure implementation, advanced energy, and the ethics of commercial spaceflight.",
//     ),
//     Senator(
//       id: "richard_blumenthal",
//       name: "Richard Blumenthal",
//       state: "Connecticut",
//       biography: "Richard Blumenthal was born in Brooklyn, New York and spent weekends at Coney Island with his immigrant parents, developing a lifelong focus on consumer protection and public safety.\n\nHe studied at Harvard College, Cambridge University, and Yale Law School and built a career as a U.S. Marine Corps Reserve captain who later served as U.S. Attorney for Connecticut and then as the state's attorney general for two decades. He became known for suing price-fixing cartels, tobacco companies, and predatory lenders.\n\nIn the Senate since 2011, Blumenthal channels that prosecutorial energy into veterans benefits, rail safety, and tech accountability, always reminding audiences that courtrooms and committee rooms share the same demand for facts.",
//     ),
//     Senator(
//       id: "chris_murphy",
//       name: "Chris Murphy",
//       state: "Connecticut",
//       biography: "Chris Murphy was born in Wethersfield, Connecticut and was the son of a community college instructor and homemaker who volunteered at local libraries, instilling a love of public service.\n\nHe studied at Williams College and the University of Connecticut School of Law and built a career as a state legislator who went on to serve three terms in the U.S. House, where he specialized in transportation and consumer issues. After the Sandy Hook shooting in his district, he became one of Congress's most visible advocates for gun violence prevention.\n\nSince joining the Senate in 2013 he has led bipartisan talks on background checks, youth mental health, and NATO policy, often linking his proposals to town hall conversations with grieving families.",
//     ),
//     Senator(
//       id: "lisa_blunt_rochester",
//       name: "Lisa Blunt Rochester",
//       state: "Delaware",
//       biography: "Lisa Blunt Rochester was born in Philadelphia and raised in Wilmington, Delaware, where she watched her parents juggle multiple jobs and community activism.\n\nShe studied at Villanova University and the University of Delaware and built a career as a county liaison, then as Delaware's secretary of labor and deputy secretary of health and social services before becoming the state's at-large member of Congress. There she focused on maternal health, broadband access, and clean energy jobs at the Port of Wilmington.\n\nElected to the Senate in 2024, Blunt Rochester centers her work on supply-chain resilience, Amtrak's Northeast Corridor, and equitable workforce pipelines for Delaware's logistics and fintech sectors.",
//     ),
//     Senator(
//       id: "chris_coons",
//       name: "Chris Coons",
//       state: "Delaware",
//       biography: "Chris Coons was born in Greenwich, Connecticut and was raised in Hockessin, Delaware, where scouting trips and mission work sparked an early interest in faith-driven service.\n\nHe studied at Amherst College and Yale, where he earned both a law degree and a Master of Divinity and built a career as counsel for W.L. Gore & Associates who later served as president of the New Castle County Council and county executive. He became known for balancing budgets during the Great Recession without slashing core services.\n\nElected in 2010, Coons is now a leading voice on foreign relations, patent policy, and workforce apprenticeships, frequently convening bipartisan prayer breakfasts and manufacturing roundtables.",
//     ),
//     Senator(
//       id: "ashley_moody",
//       name: "Ashley Moody",
//       state: "Florida",
//       biography: "Ashley Moody was born in Plant City, Florida and grew up the daughter of a judge, shadowing him at courthouses across Hillsborough County.\n\nShe studied at the University of Florida, earning business, accounting, and law degrees before becoming the youngest federal prosecutor in the Middle District of Florida and later a circuit judge. As Florida attorney general she led multistate actions on opioid trafficking and consumer fraud and modernised the state's cybercrime unit.\n\nElected to the Senate in 2024, Moody focuses on coastal resiliency funds, fentanyl interdiction, and balancing trade growth with port security for Tampa and Jacksonville.",
//     ),
//     Senator(
//       id: "rick_scott",
//       name: "Rick Scott",
//       state: "Florida",
//       biography: "Rick Scott was born in Bloomington, Illinois and grew up in public housing in Kansas City, watching his mother juggle retail jobs to keep the lights on.\n\nHe studied at the University of Missouri–Kansas City and Southern Methodist University School of Law and built a career as a Navy radar technician who later built Columbia/HCA into the nation's largest hospital company before turning to private equity. His turnaround work taught him to scrutinize budgets line by line.\n\nAfter two terms as Florida's governor, Scott joined the Senate in 2019 and now focuses on disaster preparedness, supply-chain redundancies, and fiscal restraint, often brandishing spreadsheets at hearings.",
//     ),
//     Senator(
//       id: "jon_ossoff",
//       name: "Jon Ossoff",
//       state: "Georgia",
//       biography: "Jon Ossoff was born in Atlanta, Georgia and was raised by an immigrant small-business owner and an executive at a children's hospital, spending weekends volunteering at civil rights museums and public schools.\n\nHe studied at Georgetown University's School of Foreign Service and the London School of Economics and built a career as an investigative journalist and CEO of a documentary film company that exposed corruption and war crimes on four continents. His productions helped free wrongfully jailed prisoners in Africa and Asia.\n\nElected in 2021 at age 33, Ossoff now leads bipartisan efforts on supply-chain security, clean-tech manufacturing in the South, and prison transparency, often referencing lessons from reporters and whistleblowers he once employed.",
//     ),
//     Senator(
//       id: "raphael_warnock",
//       name: "Raphael Warnock",
//       state: "Georgia",
//       biography: "Raphael Warnock was born in Savannah, Georgia and is the eleventh of twelve children who grew up in Kayton Homes public housing, where his father ran a small car-repair business under a shade tree.\n\nHe studied at Morehouse College and Union Theological Seminary and built a career as a Baptist pastor who led congregations in Baltimore and Harlem before becoming senior pastor at Ebenezer Baptist Church in Atlanta, once led by Martin Luther King Jr.. He helped expand Ebenezer's health clinic, housing ministry, and voter education programs.\n\nWarnock won special and regular elections in 2021 and 2022, bringing pulpit storytelling to debates on voting rights, agricultural equity, and student debt relief.",
//     ),
//     Senator(
//       id: "brian_schatz",
//       name: "Brian Schatz",
//       state: "Hawaii",
//       biography: "Brian Schatz was born in Ann Arbor, Michigan and moved to Honolulu as a toddler, where his parents taught at schools across Oahu and encouraged him to join debate club and canoe paddling teams.\n\nHe studied at Pomona College and built a career as a nonprofit leader who directed Helping Hands Hawaii before serving in the state legislature and as lieutenant governor. He helped launch the Hawaii Clean Energy Initiative, mapping a path to 100 percent renewables.\n\nAppointed in 2012 after Senator Daniel Inouye's death, Schatz now focuses on climate resiliency, broadband in the Pacific, and youth mental health, frequently reminding colleagues how sea-level rise threatens Waikiki and the Marshall Islands alike.",
//     ),
//     Senator(
//       id: "mazie_hirono",
//       name: "Mazie Hirono",
//       state: "Hawaii",
//       biography: "Mazie Hirono was born in Fukushima, Japan and immigrated to Honolulu at age eight with her mother and brothers, escaping an abusive marriage and starting anew in a public housing complex.\n\nShe studied at the University of Hawaii and Georgetown University Law Center and built a career as a state representative, lieutenant governor, and three-term U.S. representative who advocated for education funding and immigrant families. Her own experience learning English in Hawaii's public schools informs her policy work.\n\nSince 2013 Hirono has been one of the Senate's fiercest defenders of Title IX, maritime jobs, and veterans from the Asia-Pacific region, often hosting field hearings in Hilo, Maui, and Guam.",
//     ),
//     Senator(
//       id: "mike_crapo",
//       name: "Mike Crapo",
//       state: "Idaho",
//       biography: "Mike Crapo was born in Idaho Falls, Idaho and was one of nine siblings who took turns irrigating the family's alfalfa fields near the Snake River.\n\nHe studied at Brigham Young University and Harvard Law School and built a career as an attorney in Idaho Falls who served in the state senate, eventually becoming Senate president pro tempore before heading to the U.S. House. He specialized in water adjudication and forest management cases that crossed state lines.\n\nA senator since 1999, Crapo now shepherds tax, banking, and salmon recovery legislation, often highlighting how rural credit co-ops and tribal fisheries underpin the region's economy.",
//     ),
//     Senator(
//       id: "jim_risch",
//       name: "Jim Risch",
//       state: "Idaho",
//       biography: "Jim Risch was born in Milwaukee, Wisconsin and moved to Idaho as a teenager, working odd jobs in logging and on campus to pay tuition.\n\nHe studied at Boise State College and the University of Idaho College of Law and built a career as a prosecutor turned Ada County district attorney who later served as lieutenant governor and, briefly, governor of Idaho. He built a reputation for tough-but-pragmatic deals on wildfire response and property tax relief.\n\nSince 2009 Risch has used his foreign relations ranking seat to champion nuclear energy exports, agriculture diplomacy, and stronger alliances in the Indo-Pacific.",
//     ),
//     Senator(
//       id: "dick_durbin",
//       name: "Dick Durbin",
//       state: "Illinois",
//       biography: "Dick Durbin was born in East St. Louis, Illinois and worked evenings at his parents' small store before graduating from Assumption High School, the last class before the school closed.\n\nHe studied at Georgetown University and its law center and built a career as an attorney and aide to Senator Paul Douglas who later served in the Illinois House and then in the U.S. House starting in 1982. Durbin became known as an advocate for consumer safety, espionage law reform, and tobacco regulation.\n\nServing in the Senate since 1997, he is now majority whip and a leading voice on immigration, judgeships, and biomedical research funding at the University of Illinois system.",
//     ),
//     Senator(
//       id: "tammy_duckworth",
//       name: "Tammy Duckworth",
//       state: "Illinois",
//       biography: "Tammy Duckworth was born in Bangkok, Thailand and moved frequently across Southeast Asia before her family resettled in Honolulu, where she helped care for her younger brother while her parents rebuilt their careers.\n\nShe studied at the University of Hawaii, George Washington University, and later the Army's flight school and built a career as a helicopter pilot in the Illinois Army National Guard who lost both legs when her Black Hawk was shot down in Iraq, then led the Illinois Department of Veterans' Affairs and the federal VA's Office of Public and Intergovernmental Affairs. She championed accessible transit systems and adaptive sports programs for wounded warriors.\n\nElected in 2016, Duckworth focuses on caregiving tax credits, maternal health, and modernizing Guard equipment, often meeting newly injured service members before major votes.",
//     ),
//     Senator(
//       id: "jim_banks",
//       name: "Jim Banks",
//       state: "Indiana",
//       biography: "Jim Banks was born in Columbia City, Indiana and worked in his family's real estate business while attending community college.\n\nHe studied at Indiana University and Grace College, joined the U.S. Navy Reserve as a supply corps officer, and served in the Indiana Senate before winning a U.S. House seat where he chaired the Republican Study Committee. His legislative work centered on military readiness, rural broadband, and workforce apprenticeships supported by Indiana's manufacturing base.\n\nElected to the Senate in 2024, Banks focuses on shipbuilding supply chains, semiconductor investment along the I-69 corridor, and a veterans' services overhaul for the Midwest.",
//     ),
//     Senator(
//       id: "todd_young",
//       name: "Todd Young",
//       state: "Indiana",
//       biography: "Todd Young was born in Lancaster, Pennsylvania and moved to Carmel, Indiana, where participation in church youth groups and Boy Scouts led him toward the Naval Academy.\n\nHe studied at the U.S. Naval Academy, the University of Chicago Booth School of Business, and Indiana University McKinney School of Law and built a career as a Marine Corps intelligence officer who later worked as a management consultant and congressional staffer before winning a U.S. House seat in 2010. He helped craft the JOBS Act and other entrepreneurship policies.\n\nYoung joined the Senate in 2017 and has since focused on semiconductor incentives, adoption tax credits, and alliances in the Indo-Pacific, drawing on both his military and business background.",
//     ),
//     Senator(
//       id: "chuck_grassley",
//       name: "Chuck Grassley",
//       state: "Iowa",
//       biography: "Chuck Grassley was born in New Hartford, Iowa and grew up working on his parents' diversified farm, a routine that still finds him on a John Deere tractor every harvest season.\n\nHe studied at the University of Northern Iowa and built a career as a state legislator, factory worker, and member of the U.S. House before winning a Senate seat in 1980. His penchant for oversight hearings and annual '99 County' tours earned him the nickname 'the tweeting farmer.'\n\nGrassley is now the Senate's longest-serving Republican and remains deeply involved in judiciary, biofuels, and whistleblower protections, citing farmers and small-town sheriffs at nearly every markup.",
//     ),
//     Senator(
//       id: "joni_ernst",
//       name: "Joni Ernst",
//       state: "Iowa",
//       biography: "Joni Ernst was born in Red Oak, Iowa and grew up on a Montgomery County hog farm where she helped castrate pigs before dawn and sang in the FFA choir after school.\n\nShe studied at Iowa State University and Columbus State University and built a career as an Iowa Army National Guard lieutenant colonel who led convoys in Kuwait and Iraq before serving as county auditor and a state senator. Her 'squeal' ad about cutting pork barrel spending vaulted her onto the national stage.\n\nSince 2015 Ernst has focused on biofuel research, sexual assault prevention in the military, and child care for Guard families, drawing on her service record and life as a single mother.",
//     ),
//     Senator(
//       id: "jerry_moran",
//       name: "Jerry Moran",
//       state: "Kansas",
//       biography: "Jerry Moran was born in Great Bend, Kansas and was raised in the wheat belt, where he learned to drive combines before he could legally drive a car.\n\nHe studied at the University of Kansas and its law school and built a career as a county attorney and state senator who later represented the sprawling First District in the U.S. House, known as 'the Big First'. He logged thousands of miles holding listening sessions in every county each year.\n\nSince 2011 Moran has focused on veterans healthcare in rural areas, aviation manufacturing, and the future of Fort Riley and McConnell Air Force Base.",
//     ),
//     Senator(
//       id: "roger_marshall",
//       name: "Roger Marshall",
//       state: "Kansas",
//       biography: "Roger Marshall was born in El Dorado, Kansas and grew up in Butler County raising 4-H steers and playing high school football before attending Butler Community College.\n\nHe studied at Kansas State University and the University of Kansas School of Medicine and built a career as an obstetrician in Great Bend who delivered more than 5,000 babies and chaired the local Chamber of Commerce before entering politics. His volunteer medical trips to Haiti and Afghanistan shaped his approach to public health.\n\nElected in 2020 after two terms in the House, Marshall stresses food supply chains, telehealth, and border security through the lens of a doctor who kept rural clinics afloat.",
//     ),
//     Senator(
//       id: "mitch_mcconnell",
//       name: "Mitch McConnell",
//       state: "Kentucky",
//       biography: "Mitch McConnell was born in Sheffield, Alabama and survived polio as a toddler before moving to Louisville, where his mother insisted on rigorous physical therapy that restored his ability to walk.\n\nHe studied at the University of Louisville and the University of Kentucky College of Law and built a career as an aide to Senator Marlow Cook, a Jefferson County judge-executive, and eventually a U.S. senator first elected in 1984. He became famous for his mastery of Senate rules and his fundraising prowess for Republican candidates nationwide.\n\nAs the chamber's longest-serving party leader, McConnell wields influence over judicial confirmations, coal community aid, and federal investments in logistics hubs along the Ohio River.",
//     ),
//     Senator(
//       id: "rand_paul",
//       name: "Rand Paul",
//       state: "Kentucky",
//       biography: "Rand Paul was born in Pittsburgh, Pennsylvania and moved with his family to Texas and later Kentucky, where he worked on his father Ron Paul's congressional campaigns.\n\nHe studied at Baylor University and Duke University School of Medicine and built a career as an ophthalmologist in Bowling Green who founded a low-cost eye clinic and performed pro bono surgeries throughout the Bluegrass State. He became a favorite of the Tea Party movement by calling for balanced budgets and civil liberties protections.\n\nElected in 2010, Paul continues to champion audit-the-Fed proposals, criminal justice reform, and a noninterventionist foreign policy rooted in constitutional arguments.",
//     ),
//     Senator(
//       id: "bill_cassidy",
//       name: "Bill Cassidy",
//       state: "Louisiana",
//       biography: "Bill Cassidy was born in Highland Park, Illinois and moved to Baton Rouge as a teenager and spent weekends fishing the Atchafalaya Basin while his parents worked in education and civic service.\n\nHe studied at Louisiana State University for both undergraduate studies and medical school and built a career as a gastroenterologist who co-founded the Greater Baton Rouge Community Clinic and set up makeshift hospitals for Hurricane Katrina evacuees. He later represented Baton Rouge in the state senate and the U.S. House, where he focused on energy policy.\n\nSince 2015 Cassidy has prioritized surprise medical billing reform, carbon-capture research, and coastal restoration projects that protect Louisiana's working coast.",
//     ),
//     Senator(
//       id: "john_kennedy",
//       name: "John Kennedy",
//       state: "Louisiana",
//       biography: "John Kennedy was born in Centreville, Mississippi and grew up in Zachary, Louisiana, showing cattle at county fairs and excelling in debate.\n\nHe studied at Vanderbilt University, the University of Virginia School of Law, and Oxford University and built a career as a tax attorney who became Louisiana's secretary of revenue and later the state's longtime treasurer, famous for his colorful warnings about deficits. He was known for checking every line item in bond prospectuses before approving them.\n\nElected in 2016, Kennedy brings that fiscal hawk persona to federal hearings on flood insurance, crime, and consumer protection, often framing issues with folksy analogies.",
//     ),
//     Senator(
//       id: "susan_collins",
//       name: "Susan Collins",
//       state: "Maine",
//       biography: "Susan Collins was born in Caribou, Maine and grew up as the middle daughter in a family that ran a fifth-generation lumber business and served on the local school board.\n\nShe studied at St. Lawrence University and built a career as a congressional staffer and director of the Small Business Administration's New England regional office before running Maine's Center for Family Business. Her meticulous approach to constituent services led to record-setting bipartisan support back home.\n\nIn the Senate since 1997, Collins is known for swing votes on healthcare and Supreme Court nominees, as well as tireless advocacy for shipbuilding jobs at Bath Iron Works and for icebreaking on the Penobscot River.",
//     ),
//     Senator(
//       id: "angus_king",
//       name: "Angus King",
//       state: "Maine",
//       biography: "Angus King was born in Alexandria, Virginia and spent summer vacations in Maine, falling in love with the coast long before making Brunswick his permanent home.\n\nHe studied at Dartmouth College and the University of Virginia School of Law and built a career as an energy lawyer turned entrepreneur who invested early in cable television systems and later served two terms as Maine's independent governor. As governor he expanded laptop programs for middle schoolers and preserved millions of acres of forestland.\n\nElected as an independent in 2012, King caucuses with Democrats but often plays bridge-builder on cyber security, national parks, and offshore wind development in the Gulf of Maine.",
//     ),
//     Senator(
//       id: "angela_alsobrooks",
//       name: "Angela Alsobrooks",
//       state: "Maryland",
//       biography: "Angela Alsobrooks was born in Suitland, Maryland and raised in Prince George's County in a family that stressed public service and church volunteerism.\n\nShe studied at Duke University and the University of Maryland School of Law and built a career as a county prosecutor, later serving as state's attorney and then county executive, where she led school construction plans and Metro expansion negotiations for the Blue Line corridor.\n\nElected to the Senate in 2024, Alsobrooks prioritizes transit funding for the Capital Beltway region, small-business lending for minority entrepreneurs, and crime prevention strategies that pair community mental health with focused deterrence.",
//     ),
//     Senator(
//       id: "chris_van_hollen",
//       name: "Chris Van Hollen",
//       state: "Maryland",
//       biography: "Chris Van Hollen was born in Karachi, Pakistan and grew up in embassies overseas before his foreign service parents settled in Montgomery County, where he captained the debate team.\n\nHe studied at Swarthmore College, Harvard's Kennedy School, and Georgetown Law and built a career as a policy analyst and state legislator who went on to lead the Democratic Congressional Campaign Committee while serving in the U.S. House. He played a key role designing the 2010 budget deal that averted a government shutdown.\n\nElected in 2016, Van Hollen focuses on space policy at NASA Goddard, metro funding, and sanctions policy, often drawing on his upbringing in Cold War capitals.",
//     ),
//     Senator(
//       id: "elizabeth_warren",
//       name: "Elizabeth Warren",
//       state: "Massachusetts",
//       biography: "Elizabeth Warren was born in Oklahoma City, Oklahoma and grew up on Route 66 in a family that nearly lost its home after her father's heart attack, an event that cemented her interest in bankruptcy law.\n\nShe studied at the University of Houston and Rutgers Law School and built a career as a law professor at the University of Texas, the University of Pennsylvania, and Harvard whose research on middle-class debt helped create the Consumer Financial Protection Bureau. She chaired the Congressional Oversight Panel during the Troubled Asset Relief Program.\n\nElected in 2012, Warren presses for antitrust enforcement, affordable childcare, and student debt relief, often backing her arguments with binders full of footnotes.",
//     ),
//     Senator(
//       id: "ed_markey",
//       name: "Ed Markey",
//       state: "Massachusetts",
//       biography: "Ed Markey was born in Malden, Massachusetts and was the son of a milkman and grew up in a triple-decker where he shared a bedroom with his brothers until college.\n\nHe studied at Boston College and Boston College Law School and built a career as a state representative who kept his law books in an ice cream truck while studying for the bar, then served 37 years in the U.S. House focusing on telecom policy and environmental protection. He co-authored the original fuel-economy standards and the Waxman-Markey climate bill.\n\nServing in the Senate since 2013, Markey promotes the Green New Deal, children's online privacy, and funding for the MBTA.",
//     ),
//     Senator(
//       id: "elissa_slotkin",
//       name: "Elissa Slotkin",
//       state: "Michigan",
//       biography: "Elissa Slotkin was born in New York City and raised on a Michigan farm owned by her family that supplied parts to the auto industry.\n\nShe studied at Cornell University and Columbia University's School of International and Public Affairs, then served as a CIA analyst focused on Iraq and later as acting assistant secretary of defense for international security affairs. In the U.S. House she became known for bipartisan work on PFAS cleanup and reshoring of critical supply chains.\n\nElected to the Senate in 2024, Slotkin concentrates on Great Lakes resilience, semiconductor investment in the Midwest, and veteran and Guard benefits tied to Michigan's large defense footprint.",
//     ),
//     Senator(
//       id: "gary_peters",
//       name: "Gary Peters",
//       state: "Michigan",
//       biography: "Gary Peters was born in Pontiac, Michigan and was raised by a union teacher and a nurse's aide, delivering the Detroit Free Press before dawn.\n\nHe studied at Alma College, the University of Detroit Mercy School of Law, and the College of Naval Command and Staff and built a career as worked in finance, served in the Navy Reserve for more than 20 years, and held state senate and statewide offices before winning a U.S. House seat. He was Michigan's Lottery Commissioner, modernizing its technology.\n\nElected in 2014, Peters leads the Homeland Security Committee, where he tackles supply-chain resilience, shoreline restoration, and cybersecurity threats to automakers.",
//     ),
//     Senator(
//       id: "amy_klobuchar",
//       name: "Amy Klobuchar",
//       state: "Minnesota",
//       biography: "Amy Klobuchar was born in Plymouth, Minnesota and is the daughter of a journalist and a second-grade teacher, and learned early to combine curiosity with pragmatism while canvassing for school levies.\n\nShe studied at Yale University and the University of Chicago Law School and built a career as a corporate attorney who became Hennepin County attorney, modernizing the office's victim services and technology. She built a reputation for accountability after the I-35W bridge collapse, coordinating engineers and first responders.\n\nIn the Senate since 2007, Klobuchar focuses on competition policy, rural broadband, and election security, often citing town meetings in Iron Range gyms to explain bipartisan progress.",
//     ),
//     Senator(
//       id: "tina_smith",
//       name: "Tina Smith",
//       state: "Minnesota",
//       biography: "Tina Smith was born in Albuquerque, New Mexico and moved frequently with her Air Force family before settling in Minnesota, where she worked on college-catalyzed community service projects.\n\nShe studied at Stanford University and the Tuck School of Business at Dartmouth and built a career as a marketing professional who became chief of staff to Minneapolis Mayor R.T. Rybak and Governor Mark Dayton, then served as lieutenant governor. She helped negotiate the Vikings stadium package and led early childhood initiatives.\n\nAppointed in 2018 and then elected twice, Smith champions mental health parity, reproductive freedom, and strengthening the bio-based economy from Rochester to Duluth.",
//     ),
//     Senator(
//       id: "cindy_hyde_smith",
//       name: "Cindy Hyde-Smith",
//       state: "Mississippi",
//       biography: "Cindy Hyde-Smith was born in Brookhaven, Mississippi and showed prize cattle in local fairs and learned the rhythms of ranch life on her family's farm in Lincoln County.\n\nShe studied at Copiah-Lincoln Community College and the University of Southern Mississippi and built a career as a livestock auctioneer and state senator who later became Mississippi's commissioner of agriculture and commerce. She modernized disease-tracking systems for poultry and cattle, the state's biggest exports.\n\nAppointed in 2018 and elected later that year, Hyde-Smith focuses on crop insurance, the Gulf Coast shipyard workforce, and expanding rural clinics.",
//     ),
//     Senator(
//       id: "roger_wicker",
//       name: "Roger Wicker",
//       state: "Mississippi",
//       biography: "Roger Wicker was born in Pontotoc, Mississippi and grew up in a judge's household steeped in civic duty and joined the Air Force ROTC at Ole Miss.\n\nHe studied at the University of Mississippi for both undergraduate and law degrees and built a career as an Air Force judge advocate who later served in the Mississippi Senate and then the U.S. House beginning in 1994. He chaired the House Republican Policy Committee while championing military installations on the Gulf Coast.\n\nIn the Senate since 2007, Wicker now chairs the Commerce Committee's seas subpanel, pushing for shipbuilding contracts, coastal restoration, and broadband access along the Delta.",
//     ),
//     Senator(
//       id: "josh_hawley",
//       name: "Josh Hawley",
//       state: "Missouri",
//       biography: "Josh Hawley was born in Springdale, Arkansas and moved to Lexington, Missouri, where he devoured history books and edited the high school newspaper.\n\nHe studied at Stanford University and Yale Law School and built a career as a Supreme Court clerk for Chief Justice John Roberts, constitutional lawyer, and Missouri attorney general. He argued multiple cases defending state laws on religious liberty and consumer privacy.\n\nElected in 2018, Hawley focuses on Big Tech regulation, supply-chain nationalism, and the rights of gig economy workers, all while emphasizing a populist brand of conservatism.",
//     ),
//     Senator(
//       id: "eric_schmitt",
//       name: "Eric Schmitt",
//       state: "Missouri",
//       biography: "Eric Schmitt was born in Bridgeton, Missouri and was raised by a union electrician and a preschool teacher, playing defensive tackle at De Smet Jesuit High School.\n\nHe studied at Truman State University and Saint Louis University School of Law and built a career as a private attorney who served as an alderman, state senator, state treasurer, and then Missouri attorney general. He spearheaded lawsuits on behalf of parents of children with special needs, inspired by his own son's autism diagnosis.\n\nSchmitt won a Senate seat in 2022 and now concentrates on energy policy, parental rights, and reshoring advanced manufacturing in the St. Louis corridor.",
//     ),
//     Senator(
//       id: "tim_sheehy",
//       name: "Tim Sheehy",
//       state: "Montana",
//       biography: "Tim Sheehy was born in Stillwater, Minnesota and attended the U.S. Naval Academy, where he trained as a Navy SEAL and later deployed to Afghanistan and Iraq.\n\nAfter combat service he settled in Montana and founded Bridger Aerospace, a wildfire aviation and drone services company that works closely with the Forest Service. He also runs a ranch near Bozeman and mentors veteran entrepreneurs in the Mountain West.\n\nElected to the Senate in 2024, Sheehy focuses on wildfire prevention, resilient timber and grazing policies, and ensuring the Air National Guard and missile fields across Montana receive modern equipment and housing.",
//     ),
//     Senator(
//       id: "steve_daines",
//       name: "Steve Daines",
//       state: "Montana",
//       biography: "Steve Daines was born in Van Hook, North Dakota and moved to Bozeman as a child, where he joined Scouts, hunted elk, and helped his parents run a small surveying business.\n\nHe studied at Montana State University with a degree in chemical engineering and built a career as spent 13 years as a Procter & Gamble executive launching factories in Asia before returning to Montana to work for RightNow Technologies, a Bozeman cloud company. He also served as Montana chair for the American Red Cross during wildfire seasons.\n\nElected to the Senate in 2014, Daines focuses on forest management, semiconductor incentives in the Mountain West, and securing northern border crossings.",
//     ),
//     Senator(
//       id: "deb_fischer",
//       name: "Deb Fischer",
//       state: "Nebraska",
//       biography: "Deb Fischer was born in Lincoln, Nebraska and spent summers fixing fence on her family's Sandhills ranch and learning parliamentary procedure through 4-H.\n\nShe studied at the University of Nebraska–Lincoln and built a career as a rancher who served on the local school board for 18 years before winning a seat in the unicameral Nebraska Legislature. She chaired the Transportation and Telecommunications Committee, securing funding for expressways.\n\nIn the Senate since 2013, Fischer champions precision agriculture, military family housing at Offutt Air Force Base, and pragmatic infrastructure budgeting.",
//     ),
//     Senator(
//       id: "pete_ricketts",
//       name: "Pete Ricketts",
//       state: "Nebraska",
//       biography: "Pete Ricketts was born in Nebraska City, Nebraska and grew up in a family that founded TD Ameritrade, learning investment basics at the dinner table while also volunteering at Boys Town.\n\nHe studied at the University of Chicago for both undergraduate and MBA degrees and built a career as helped build TD Ameritrade into a national brokerage, then served two terms as Nebraska's governor from 2015 to 2023. His administration emphasized property tax cuts, flood recovery, and public-private partnerships for workforce housing.\n\nAppointed in 2023 to succeed Ben Sasse, Ricketts now works on trade, rail chokepoints, and protecting the meatpacking supply chain.",
//     ),
//     Senator(
//       id: "catherine_cortez_masto",
//       name: "Catherine Cortez Masto",
//       state: "Nevada",
//       biography: "Catherine Cortez Masto was born in Las Vegas, Nevada and is the granddaughter of a Mexican immigrant who built one of the city's first grocery stores, and she watched the valley grow from a dusty outpost to a global tourism hub.\n\nShe studied at the University of Nevada, Reno and Gonzaga University School of Law and built a career as served as chief of staff to Governor Bob Miller, federal prosecutor, and later Nevada's attorney general. She prosecuted mortgage fraud during the Great Recession and established the state's first senior protection unit.\n\nElected in 2016, Cortez Masto focuses on drought resilience, tribal broadband, and consumer protections for service workers on the Strip.",
//     ),
//     Senator(
//       id: "jacky_rosen",
//       name: "Jacky Rosen",
//       state: "Nevada",
//       biography: "Jacky Rosen was born in Chicago, Illinois and was the first in her family to attend college and paid tuition by waiting tables and writing software on the side.\n\nShe studied at the University of Minnesota and built a career as a computer programmer for major casinos who later became president of Congregation Ner Tamid in Henderson. She launched a food pantry and interfaith partnerships during the Great Recession.\n\nAfter one term in the U.S. House she flipped a Senate seat in 2018 and now champions STEM apprenticeships, aviation innovation at Harry Reid International Airport, and support for caregivers of veterans.",
//     ),
//     Senator(
//       id: "jeanne_shaheen",
//       name: "Jeanne Shaheen",
//       state: "New Hampshire",
//       biography: "Jeanne Shaheen was born in St. Charles, Missouri and moved frequently as the daughter of an Army engineer before settling in New Hampshire to teach high school and coach a girls' basketball team.\n\nShe studied at Shippensburg University and the University of Mississippi and built a career as ran a small jewelry business, served in the state senate, and became the first woman elected governor of New Hampshire. Her administration expanded kindergarten, created the Job Training Fund, and navigated the aftermath of the 9/11 attacks.\n\nIn the Senate since 2009, Shaheen works on small-business lending, energy efficiency for cold climates, and bipartisan diplomacy through the Foreign Relations Committee.",
//     ),
//     Senator(
//       id: "maggie_hassan",
//       name: "Maggie Hassan",
//       state: "New Hampshire",
//       biography: "Maggie Hassan was born in Boston, Massachusetts and is the daughter of an Army research physician who instilled a commitment to public service and problem-solving.\n\nShe studied at Brown University and Northeastern University School of Law and built a career as served as New Hampshire's governor, where she expanded Medicaid and negotiated a commuter rail agreement, after previously working as an attorney and state senator. Her advocacy for people with disabilities is informed by raising a son with cerebral palsy.\n\nElected to the Senate in 2016, Hassan focuses on cybersecurity workforce training, fentanyl interdiction, and lowering energy costs for New England families.",
//     ),
//     Senator(
//       id: "andy_kim",
//       name: "Andy Kim",
//       state: "New Jersey",
//       biography: "Andy Kim was born in Boston, Massachusetts and raised in southern New Jersey by Korean immigrant parents who ran a liquor store and stressed public education and service.\n\nHe studied at the University of Chicago and Oxford as a Rhodes Scholar and built a career as a national security adviser, serving on the National Security Council and as a civilian adviser in Afghanistan. Elected to the U.S. House in 2018, he focused on veterans' health, resiliency at Joint Base McGuire-Dix-Lakehurst, and flood mitigation along the Jersey Shore.\n\nElected to the Senate in 2024, Kim works on military readiness, coastal infrastructure for Barnegat Bay, and ethics reforms to rebuild trust in New Jersey politics.",
//     ),
//     Senator(
//       id: "cory_booker",
//       name: "Cory Booker",
//       state: "New Jersey",
//       biography: "Cory Booker was born in Washington, D.C. and grew up in Harrington Park, New Jersey, where his parents broke color barriers as IBM executives and taught their son to challenge housing discrimination.\n\nHe studied at Stanford University, Oxford University as a Rhodes Scholar, and Yale Law School and built a career as a tenants' rights attorney who moved into Newark public housing, served on the city council, and was elected mayor, drawing national attention for hands-on crisis response. He famously shoveled residents' driveways during blizzards and rescued a neighbor from a burning home.\n\nSince 2013 Booker has focused on criminal justice reform, community finance, and nutrition policy, bringing Newark stories into every committee room.",
//     ),
//     Senator(
//       id: "martin_heinrich",
//       name: "Martin Heinrich",
//       state: "New Mexico",
//       biography: "Martin Heinrich was born in Fallon, Nevada and was raised in Silver City, New Mexico, where Boy Scout hikes through the Gila Wilderness sparked a lifelong passion for public lands.\n\nHe studied at the University of Missouri with a mechanical engineering degree and built a career as worked as an engineer at Phillips Laboratories, founded a solar company, and served on the Albuquerque City Council before winning a U.S. House seat. He helped create the Bosque School's environmental program and served as New Mexico's natural resources trustee.\n\nIn the Senate since 2013, Heinrich champions outdoor recreation economies, national labs, and bipartisan privacy reforms for emerging technology.",
//     ),
//     Senator(
//       id: "ben_ray_lujan",
//       name: "Ben Ray Luján",
//       state: "New Mexico",
//       biography: "Ben Ray Lujan was born in Santa Fe, New Mexico and is the son of longtime state House Speaker Ben Lujan and grew up near the Pojoaque Valley attending pueblo dances and rodeos.\n\nHe studied at the University of New Mexico and built a career as held posts in the state's cultural affairs and public regulation commissions before winning a U.S. House seat in 2008, eventually chairing the Democratic Congressional Campaign Committee. He helped expand broadband to rural pueblos and launched the 'Young Guns' recruitment program.\n\nElected in 2020, Lujan now focuses on wildfire recovery, microelectronics research at Sandia and Los Alamos, and healthcare access for tribal communities.",
//     ),
//     Senator(
//       id: "chuck_schumer",
//       name: "Chuck Schumer",
//       state: "New York",
//       biography: "Chuck Schumer was born in Brooklyn, New York and is the son of a pest exterminator and a homemaker, and he carried flashcards on the subway to prepare for debate tournaments at Madison High School.\n\nHe studied at Harvard College and Harvard Law School and built a career as elected to the New York State Assembly at 23, then to the U.S. House, where he chaired the Judiciary Subcommittee on Crime and authored the Brady Bill. He built a reputation for Sunday press conferences on every corner of New York City.\n\nIn the Senate since 1999 and now majority leader, Schumer works on semiconductor incentives, transit megaprojects, and judicial confirmations, all while holding fast to his Brooklyn roots.",
//     ),
//     Senator(
//       id: "kirsten_gillibrand",
//       name: "Kirsten Gillibrand",
//       state: "New York",
//       biography: "Kirsten Gillibrand was born in Albany, New York and grew up in a politically active family—her grandmother organized secretary unions at the state Capitol—instilling a penchant for coalition building.\n\nShe studied at Dartmouth College and UCLA School of Law and built a career as a corporate attorney who served as special counsel at HUD before winning a rural upstate congressional seat in 2006. She launched the first congressional transparency database of earmarks and meetings.\n\nAppointed in 2009 and elected statewide since, Gillibrand leads on military sexual assault reform, paid family leave, and PFAS cleanup around upstate air bases.",
//     ),
//     Senator(
//       id: "thom_tillis",
//       name: "Thom Tillis",
//       state: "North Carolina",
//       biography: "Thom Tillis was born in Jacksonville, Florida and was raised in a working-class family that moved frequently, forcing him to attend five high schools before settling in Nashville, Tennessee.\n\nHe studied at the University of Maryland Global Campus while working full time at IBM and built a career as a management consultant at PricewaterhouseCoopers and IBM who later won a seat in the North Carolina House, rising to speaker. He led major tort, tax, and education overhauls in Raleigh.\n\nSince 2015 Tillis has focused on immigration modernization, veteran suicide prevention at Fort Bragg, and semiconductor investments in the Research Triangle.",
//     ),
//     Senator(
//       id: "ted_budd",
//       name: "Ted Budd",
//       state: "North Carolina",
//       biography: "Ted Budd was born in Winston-Salem, North Carolina and split time between a small family farm and a garden center, learning to repair tractors before he could drive.\n\nHe studied at Appalachian State University, Dallas Theological Seminary for a master's in business, and Wake Forest University School of Business and built a career as owns a gun store and range and ran the Budd Group, his family's facility-services company, before winning a U.S. House seat in 2016. He helped shepherd bipartisan financial technology legislation through the House.\n\nBudd joined the Senate in 2023 and now emphasizes supply-chain security, rural broadband, and protecting North Carolina's military installations from encroachment.",
//     ),
//     Senator(
//       id: "john_hoeven",
//       name: "John Hoeven",
//       state: "North Dakota",
//       biography: "John Hoeven was born in Bismarck, North Dakota and is the son of a banker, and he worked summers at community pools before heading to Dartmouth.\n\nHe studied at Dartmouth College and Northwestern University's Kellogg School of Management and built a career as headed the state's largest community bank before serving a decade as North Dakota's governor, overseeing the Bakken shale boom. He launched the North Dakota Medora Foundation and championed value-added agriculture.\n\nSince 2011 Hoeven has focused on farm insurance, tribal partnerships, and veterans clinics for the rural High Plains.",
//     ),
//     Senator(
//       id: "kevin_cramer",
//       name: "Kevin Cramer",
//       state: "North Dakota",
//       biography: "Kevin Cramer was born in Rolette, North Dakota and grew up in a railroad family, bagging groceries and delivering papers in Kindred.\n\nHe studied at Concordia College and the University of Mary and built a career as served as state tourism director, economic development director, and Public Service Commissioner before winning a U.S. House seat in 2012. He oversaw pipeline safety and telecom expansion during the oil boom.\n\nElected to the Senate in 2018, Cramer advocates for carbon capture, national defense missions at Grand Forks, and pro-life policies.",
//     ),
//     Senator(
//       id: "bernie_moreno",
//       name: "Bernie Moreno",
//       state: "Ohio",
//       biography: "Bernie Moreno was born in Bogotá, Colombia and immigrated to the United States with his family at age five, growing up in the Boston area before heading to college in Michigan.\n\nHe studied at the University of Michigan and built a career as a luxury auto dealer in Ohio, later investing in blockchain technology and workforce training programs tied to Cleveland's port and manufacturing corridor. He chaired regional civic groups focused on entrepreneurship and public-private partnerships.\n\nElected to the Senate in 2024, Moreno prioritizes trade competitiveness on the Great Lakes, precision manufacturing apprenticeships, and stern oversight of border and visa systems to ensure legal pathways keep pace with employer demand.",
//     ),
//     Senator(
//       id: "jon_husted",
//       name: "Jon Husted",
//       state: "Ohio",
//       biography: "Jon Husted was born in Royal Oak, Michigan and adopted by a working-class family in Montpelier, Ohio, where sports scholarships opened doors to college.\n\nHe studied at the University of Dayton, played on a national championship football team, and entered public service as a state representative, later becoming Speaker of the Ohio House and then Secretary of State. As lieutenant governor he led broadband expansion and workforce initiatives linking community colleges to advanced manufacturing employers.\n\nAppointed to the Senate in 2025 after the vice president vacated the seat, Husted now focuses on rail safety, reshoring EV supply chains around Columbus and Toledo, and modernising federal cyber standards for local governments.",
//     ),
//     Senator(
//       id: "james_lankford",
//       name: "James Lankford",
//       state: "Oklahoma",
//       biography: "James Lankford was born in Dallas, Texas and spent summers at Falls Creek Baptist Camp in Oklahoma, eventually directing the camp for teenagers from all 77 counties.\n\nHe studied at the University of Texas and Southwestern Baptist Theological Seminary and built a career as served as director of Falls Creek youth camp for 13 years before winning a U.S. House seat in 2010. He became known for budget watchdog reports that cataloged federal waste.\n\nSince 2015 Lankford has led bipartisan work on government transparency, tribal sovereignty, and the modernization of the IRS customer service model.",
//     ),
//     Senator(
//       id: "markwayne_mullin",
//       name: "Markwayne Mullin",
//       state: "Oklahoma",
//       biography: "Markwayne Mullin was born in Tulsa, Oklahoma and was raised on a ranch near Westville, helping run the family plumbing company after his father's illness.\n\nHe studied at Oklahoma State University Institute of Technology and built a career as expanded Mullin Plumbing into multiple businesses and became known as a champion wrestler before winning a U.S. House seat in 2012. He is one of the few enrolled members of a federally recognized tribe (Cherokee Nation) to serve in Congress.\n\nElected in 2022, Mullin advocates for tribal sovereignty, domestic energy production, and skilled trade education, often bringing his work boots to committee hearings.",
//     ),
//     Senator(
//       id: "ron_wyden",
//       name: "Ron Wyden",
//       state: "Oregon",
//       biography: "Ron Wyden was born in Wichita, Kansas and moved to California as a child, where his Holocaust-survivor parents encouraged him to start a basketball league for low-income kids.\n\nHe studied at the University of California, Santa Barbara and Stanford University, followed by the University of Oregon School of Law and built a career as co-founded the Oregon Gray Panthers, a seniors advocacy group, before serving in the U.S. House from 1981 to 1996. He became known for 'Oregon Trail' town halls, promising to visit each county every year.\n\nIn the Senate Wyden chairs the Finance Committee and champions privacy rights, timber restoration, and clean energy tax credits.",
//     ),
//     Senator(
//       id: "jeff_merkley",
//       name: "Jeff Merkley",
//       state: "Oregon",
//       biography: "Jeff Merkley was born in Myrtle Creek, Oregon and spent part of his childhood in a mobile home park while his father worked as a mechanic, instilling empathy for families on the edge.\n\nHe studied at Stanford University and Princeton University's Woodrow Wilson School and built a career as an energy analyst at the Congressional Budget Office who returned to Oregon to serve in the state legislature, becoming speaker of the House during the Great Recession. He expanded affordable housing trust funds and cracked down on payday lending.\n\nSince 2009 Merkley has pressed for climate justice, reforming the Senate filibuster, and supporting refugees who resettle in the Pacific Northwest.",
//     ),
//     Senator(
//       id: "dave_mccormick",
//       name: "Dave McCormick",
//       state: "Pennsylvania",
//       biography: "Dave McCormick was born in Washington, Pennsylvania and raised in Bloomsburg, where his family's apple orchard doubled as his first job site.\n\nHe studied at West Point and served as an Army Ranger during the Gulf War before earning a PhD at Princeton and moving into business, eventually leading a major hedge fund. In government he served as Undersecretary of the Treasury for International Affairs, working on export controls and currency policy.\n\nElected to the Senate in 2024, McCormick focuses on critical minerals, supply chain resilience for Pennsylvania manufacturers, and support for veterans transitioning into tech and energy jobs across the Allegheny corridor.",
//     ),
//     Senator(
//       id: "john_fetterman",
//       name: "John Fetterman",
//       state: "Pennsylvania",
//       biography: "John Fetterman was born in Reading, Pennsylvania and was raised in York by parents who emphasized service despite comfortable means, a perspective that deepened when a close friend died in a car accident.\n\nHe studied at Albright College, the University of Connecticut, and Harvard's Kennedy School and built a career as served as mayor of Braddock for 13 years, launching urban gardens, legal clinics, and art initiatives to breathe new life into the steel town. As lieutenant governor he chaired the Board of Pardons and championed criminal justice reform.\n\nFetterman won a 2022 Senate race while recovering from a stroke, and he now focuses on rail safety, the steel supply chain, and mental health care access.",
//     ),
//     Senator(
//       id: "jack_reed",
//       name: "Jack Reed",
//       state: "Rhode Island",
//       biography: "Jack Reed was born in Cranston, Rhode Island and was the son of a school janitor and a seamstress, and he helped care for younger cousins in the close-knit neighborhood.\n\nHe studied at the U.S. Military Academy at West Point, Harvard's Kennedy School, and Harvard Law School and built a career as served as an Army Ranger and paratrooper, taught at West Point, and later became a state senator and U.S. representative. He specialized in housing finance at a Providence law firm before entering Congress.\n\nIn the Senate since 1997, Reed chairs the Armed Services Committee and consistently advocates for the Navy's undersea fleet and for affordable housing along Narragansett Bay.",
//     ),
//     Senator(
//       id: "sheldon_whitehouse",
//       name: "Sheldon Whitehouse",
//       state: "Rhode Island",
//       biography: "Sheldon Whitehouse was born in New York City, New York and lived overseas while his father served as a diplomat, eventually returning to Rhode Island for high school.\n\nHe studied at Yale University and the University of Virginia School of Law and built a career as was Rhode Island's U.S. attorney and attorney general, notable for prosecuting public corruption and corporate polluters. He negotiated the Master Settlement Agreement with tobacco companies.\n\nSince 2007 Whitehouse has focused on climate accountability, Supreme Court ethics, and protecting the state's coastal fisheries from warming waters.",
//     ),
//     Senator(
//       id: "lindsey_graham",
//       name: "Lindsey Graham",
//       state: "South Carolina",
//       biography: "Lindsey Graham was born in Central, South Carolina and was the first in his family to attend college, supporting his parents' pool hall while they battled illness.\n\nHe studied at the University of South Carolina for both undergraduate and law degrees and built a career as served as an Air Force and Air National Guard judge advocate, then as a state representative and U.S. House member beginning in 1994. He deployed to Iraq and Afghanistan as a reservist even while serving in Congress.\n\nIn the Senate since 2003, Graham works on military readiness at bases like Fort Jackson and Parris Island, while also crafting bipartisan criminal justice reforms and judiciary legislation.",
//     ),
//     Senator(
//       id: "tim_scott",
//       name: "Tim Scott",
//       state: "South Carolina",
//       biography: "Tim Scott was born in North Charleston, South Carolina and was raised by a single mother who worked double shifts as a nurse's aide, and a Chick-fil-A mentor steered him toward business classes.\n\nHe studied at Charleston Southern University and built a career as launched an insurance and real estate company, served on the Charleston County Council, in the state house, and then in the U.S. House. He authored 'Opportunity Zone' policies to spur investment in distressed neighborhoods.\n\nAppointed in 2013 and later elected statewide, Scott focuses on workforce apprenticeships, policing reform, and flood mitigation along the Lowcountry coast.",
//     ),
//     Senator(
//       id: "john_thune",
//       name: "John Thune",
//       state: "South Dakota",
//       biography: "John Thune was born in Pierre, South Dakota and was the son of a World War II fighter pilot and grew up playing basketball and selling popcorn at the local theater.\n\nHe studied at Biola University and the University of South Dakota and built a career as worked in the late Senator James Abdnor's office, led the South Dakota Railroad Administration, and served in the U.S. House from 1996 to 2002. He later headed the South Dakota Municipal League, focusing on water projects.\n\nElected to the Senate in 2004, Thune now serves as Republican whip and concentrates on rail policy, Ellsworth Air Force Base missions, and rural broadband.",
//     ),
//     Senator(
//       id: "mike_rounds",
//       name: "Mike Rounds",
//       state: "South Dakota",
//       biography: "Mike Rounds was born in Huron, South Dakota and was the eldest of eleven children in a family that ran an insurance agency and taught all the kids to work the phones.\n\nHe studied at South Dakota State University and built a career as co-owned Fischer Rounds Insurance and served in the state senate for a decade before becoming governor from 2003 to 2011. His governorship emphasized biotech recruitment and rebuilding after the 2011 Missouri River floods.\n\nSince 2015 Rounds has focused on banking innovation, tribal housing, and the modernization of the Air National Guard's 114th Fighter Wing.",
//     ),
//     Senator(
//       id: "marsha_blackburn",
//       name: "Marsha Blackburn",
//       state: "Tennessee",
//       biography: "Marsha Blackburn was born in Laurel, Mississippi and was raised in a small delta town before moving to Tennessee for college, selling books door to door to pay tuition.\n\nShe studied at Mississippi State University and built a career as a marketing executive for the Castner Knott retail chain who later served in the Tennessee Senate and the U.S. House. She organized a statewide grassroots movement against a proposed state income tax.\n\nElected in 2018, Blackburn focuses on intellectual property enforcement in the music industry, broadband for Appalachia, and countering Chinese influence in supply chains.",
//     ),
//     Senator(
//       id: "bill_hagerty",
//       name: "Bill Hagerty",
//       state: "Tennessee",
//       biography: "Bill Hagerty was born in Gallatin, Tennessee and grew up on a cattle farm in Sumner County before pursuing finance in Nashville.\n\nHe studied at Vanderbilt University for both undergraduate and law degrees and built a career as worked in private equity, served as Tennessee's commissioner of economic development, and was U.S. ambassador to Japan from 2017 to 2019. He led recruitment of auto plants and tech campuses to the Volunteer State.\n\nElected in 2020, Hagerty now concentrates on Indo-Pacific alliances, automotive trade, and keeping Tennessee a magnet for investment.",
//     ),
//     Senator(
//       id: "john_cornyn",
//       name: "John Cornyn",
//       state: "Texas",
//       biography: "John Cornyn was born in Houston, Texas and moved frequently as the son of an Air Force pilot, attending high school on military bases in Japan and South Carolina before returning to San Antonio.\n\nHe studied at Trinity University, St. Mary's University School of Law, and the University of Virginia School of Law and built a career as practiced law in San Antonio, served as a state district judge, Texas Supreme Court justice, and Texas attorney general. As attorney general he created the state's first internet crimes against children task force.\n\nIn the Senate since 2002 and a former majority whip, Cornyn focuses on border modernization, semiconductor incentives in Texas, and mental health partnerships with law enforcement.",
//     ),
//     Senator(
//       id: "ted_cruz",
//       name: "Ted Cruz",
//       state: "Texas",
//       biography: "Ted Cruz was born in Calgary, Alberta and moved to Houston as a child, where his father ran an oilfield service business and his mother wrote computer software.\n\nHe studied at Princeton University and Harvard Law School and built a career as clerked for Chief Justice William Rehnquist, served as Texas solicitor general, and argued nine cases before the U.S. Supreme Court. He became a national Tea Party figure during the Affordable Care Act debates.\n\nSince 2013 Cruz has focused on energy independence, limiting federal regulation, and strengthening missile defense, often citing Texas's role as a space and energy leader.",
//     ),
//     Senator(
//       id: "mike_lee",
//       name: "Mike Lee",
//       state: "Utah",
//       biography: "Mike Lee was born in Mesa, Arizona and was raised in Provo, Utah, where his father served as solicitor general and instilled a love of constitutional history.\n\nHe studied at Brigham Young University for both undergraduate and law degrees and built a career as clerked for Justice Samuel Alito, worked as an assistant U.S. attorney, and served as general counsel to Utah Governor Jon Huntsman. He later became a prominent litigator in energy and technology cases.\n\nElected in 2010, Lee is known for constitutional originalism, reforms to the Antiquities Act, and bipartisan bills on rail safety and tech competition.",
//     ),
//     Senator(
//       id: "john_curtis",
//       name: "John Curtis",
//       state: "Utah",
//       biography: "John Curtis was born in Salt Lake City, Utah and spent much of his career in the private sector as a small-business owner and executive before entering politics.\n\nHe studied at Brigham Young University and later served as mayor of Provo, where he oversaw downtown revitalization and fiber broadband expansion. Elected to the U.S. House in 2017, he founded the Conservative Climate Caucus and worked on public lands collaboration across the Intermountain West.\n\nElected to the Senate in 2024, Curtis concentrates on water allocation in the Colorado River Basin, wildfire mitigation for Wasatch Front communities, and clean-tech manufacturing that leverages Utah's universities and startups.",
//     ),
//     Senator(
//       id: "bernie_sanders",
//       name: "Bernie Sanders",
//       state: "Vermont",
//       biography: "Bernie Sanders was born in Brooklyn, New York and grew up in a rent-controlled apartment, the son of a paint salesman who fled Nazi-occupied Poland.\n\nHe studied at the University of Chicago and built a career as moved to Vermont as part of the back-to-the-land movement, worked as a carpenter and film maker, and was elected mayor of Burlington in 1981 before serving in the U.S. House. He built the Burlington waterfront bike path and launched one of the nation's first community-trust funds for small businesses.\n\nIn the Senate since 2007, Sanders caucuses with Democrats but remains an independent voice for Medicare for All, labor rights, and climate investment.",
//     ),
//     Senator(
//       id: "peter_welch",
//       name: "Peter Welch",
//       state: "Vermont",
//       biography: "Peter Welch was born in Springfield, Massachusetts and moved to Vermont after college, working construction jobs and volunteering for legal aid clients.\n\nHe studied at the College of the Holy Cross and the University of California, Berkeley School of Law and built a career as served as a public defender, state senator, and president pro tempore of the Vermont Senate before winning a U.S. House seat in 2006. He helped broker Vermont's landmark civil unions legislation.\n\nElected to the Senate in 2022, Welch focuses on broadband for rural valleys, insulin price caps, and support for dairy farmers navigating volatile markets.",
//     ),
//     Senator(
//       id: "mark_warner",
//       name: "Mark Warner",
//       state: "Virginia",
//       biography: "Mark Warner was born in Indianapolis, Indiana and grew up in a middle-class family that moved to Connecticut, where he was the first in his family to finish college.\n\nHe studied at George Washington University and Harvard Law School and built a career as a venture capitalist who invested early in wireless spectrum and helped build Nextel, later serving as Virginia's governor from 2002 to 2006. As governor he closed a massive budget shortfall while expanding broadband to rural Appalachia.\n\nIn the Senate since 2009, Warner co-chairs the Senate Cybersecurity Caucus and brokers bipartisan deals on infrastructure finance and workforce retraining.",
//     ),
//     Senator(
//       id: "tim_kaine",
//       name: "Tim Kaine",
//       state: "Virginia",
//       biography: "Tim Kaine was born in St. Paul, Minnesota and spent a year as a Jesuit missionary in Honduras while in law school, cementing his commitment to service and fluent Spanish.\n\nHe studied at the University of Missouri and Harvard Law School and built a career as a civil rights lawyer who served as mayor of Richmond, lieutenant governor, governor, and vice-presidential nominee in 2016. He expanded pre-K and the Virginia Community College System's transfer grants.\n\nSince 2013 Kaine has concentrated on military family housing in Hampton Roads, war powers reform, and affordable housing around the Washington Metro.",
//     ),
//     Senator(
//       id: "patty_murray",
//       name: "Patty Murray",
//       state: "Washington",
//       biography: "Patty Murray was born in Bothell, Washington and is the daughter of a World War II veteran who ran a family lumber company before falling ill, forcing her mother back to school to become an accountant.\n\nShe studied at Washington State University and built a career as taught preschool, organized PTA campaigns, and served on the Shoreline School Board before winning seats in the Washington State Senate and then the U.S. Senate in 1992. Dubbed 'the mom in tennis shoes,' she blocked repeated attempts to cut education for disabled children.\n\nMurray is now the Senate president pro tempore and chairs the Appropriations Committee, focusing on childcare, veterans' hospitals, and salmon recovery across the Pacific Northwest.",
//     ),
//     Senator(
//       id: "maria_cantwell",
//       name: "Maria Cantwell",
//       state: "Washington",
//       biography: "Maria Cantwell was born in Indianapolis, Indiana and moved to Ohio as a child, helping in her parents' ice cream shop before volunteering for local fair-housing campaigns.\n\nShe studied at Miami University in Ohio and built a career as served in the Washington House, the U.S. House, and as an executive at streaming pioneer RealNetworks before returning to public service. She helped bring the Seattle Mariners ballpark deal across the finish line and defended the Hanford cleanup budget.\n\nElected in 2000, Cantwell is a leader on aviation safety, net neutrality, and fuel economy standards that keep Boeing, Amazon, and rural cooperatives thriving together.",
//     ),
//     Senator(
//       id: "jim_justice",
//       name: "Jim Justice",
//       state: "West Virginia",
//       biography: "Jim Justice was born in Charleston, West Virginia and grew up running heavy equipment on his family's farms and coal operations, experience he credits for his focus on extraction safety.\n\nHe studied at Marshall University and built a business empire spanning coal, agriculture, and resorts, including rescuing The Greenbrier out of bankruptcy. Elected governor in 2016, he invested in road upgrades, broadband expansion, and teacher pay raises while presiding over flood recovery efforts.\n\nElected to the Senate in 2024, Justice emphasizes energy dominance with carbon capture, workforce training for miners moving into construction and manufacturing, and Appalachian flood control projects that protect holler communities.",
//     ),
//     Senator(
//       id: "shelley_moore_capito",
//       name: "Shelley Moore Capito",
//       state: "West Virginia",
//       biography: "Shelley Moore Capito was born in Glen Dale, West Virginia and is the daughter of former Governor Arch Moore and spent childhood weekends at high school football games and union picnics across the state.\n\nShe studied at Duke University and the University of Virginia and built a career as worked as a college career counselor and in community outreach before serving in the West Virginia House and then the U.S. House for 14 years. She built the bipartisan Congressional Caucus for Women's Issues.\n\nSince 2015 Capito has prioritized broadband deployment, opioid treatment resources, and transportation funding along Corridor H.",
//     ),
//     Senator(
//       id: "tammy_baldwin",
//       name: "Tammy Baldwin",
//       state: "Wisconsin",
//       biography: "Tammy Baldwin was born in Madison, Wisconsin and was raised by her grandparents after her teenage mother faced mental health struggles, and she spent weeks in the hospital battling a childhood virus that left her with a preexisting condition.\n\nShe studied at Smith College and the University of Wisconsin Law School and built a career as served on the Dane County Board, in the Wisconsin Assembly, and in the U.S. House, where she co-founded the Congressional LGBTQ+ Equality Caucus. She authored one of the first bills to allow generic biologic drugs.\n\nElected in 2012 as the nation's first openly gay senator, Baldwin champions Buy American rules, Great Lakes cleanup, and rural healthcare clinics.",
//     ),
//     Senator(
//       id: "ron_johnson",
//       name: "Ron Johnson",
//       state: "Wisconsin",
//       biography: "Ron Johnson was born in Mankato, Minnesota and moved to Wisconsin for college and worked nights to pay tuition, eventually helping his brother-in-law start the plastics company Pacur in Oshkosh.\n\nHe studied at the University of Minnesota and built a career as ran Pacur for decades, producing medical packaging and employing hundreds in the Fox Valley. He joined TEA Party rallies calling for lower taxes and simpler regulations.\n\nSince 2011 Johnson has focused on manufacturing supply chains, deficits, and investigations through the Homeland Security Committee.",
//     ),
//     Senator(
//       id: "john_barrasso",
//       name: "John Barrasso",
//       state: "Wyoming",
//       biography: "John Barrasso was born in Reading, Pennsylvania and moved west for medical school rotations and fell in love with Casper's open plains, eventually becoming known as 'Wyoming's doctor'.\n\nHe studied at Georgetown University and the Georgetown University School of Medicine and built a career as an orthopedic surgeon who served as president of the Wyoming Medical Society and a state senator before being appointed to the U.S. Senate in 2007. He hosted a long-running health tips segment on Wyoming television.\n\nBarrasso is now the Senate Republican Conference chair and advocates for energy independence, federal land access, and rural hospitals from Cheyenne to Cody.",
//     ),
//     Senator(
//       id: "cynthia_lummis",
//       name: "Cynthia Lummis",
//       state: "Wyoming",
//       biography: "Cynthia Lummis was born in Cheyenne, Wyoming and was elected to the state House at 24 and balanced legislative sessions with tending her family's cattle ranch.\n\nShe studied at the University of Wyoming for both animal science and law degrees and built a career as served as state treasurer, on the Wyoming Supreme Court's staff, and in the U.S. House from 2008 to 2016 before returning to ranching. She became an early advocate for digital asset regulation after investing personally in bitcoin.\n\nElected in 2020, Lummis pushes for responsible crypto frameworks, Powder River Basin jobs, and protection of the Wyoming Range.",
//     ),
//   ]
// }

// pub fn all() -> List(Senator) {
//   all_senators()
// }
