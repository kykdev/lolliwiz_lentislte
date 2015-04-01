#define DEF_SAMPLING_MS			(268)

static struct delayed_work intelli_plug_work;
static struct delayed_work intelli_plug_boost;

static struct workqueue_struct *intelliplug_wq;
static struct workqueue_struct *intelliplug_boost_wq;

static unsigned int intelli_plug_active = 0;
module_param(intelli_plug_active, uint, 0664);

static unsigned int touch_boost_active = 1;
module_param(touch_boost_active, uint, 0664);

static unsigned int nr_run_profile_sel = 0;
module_param(nr_run_profile_sel, uint, 0664);

//default to something sane rather than zero
static unsigned int sampling_time = DEF_SAMPLING_MS;

void __ref intelli_plug_perf_boost(bool on)
{
	unsigned int cpu;

	if (intelli_plug_active) {
		flush_workqueue(intelliplug_wq);
		if (on) {
			for_each_possible_cpu(cpu) {
				if (!cpu_online(cpu))
					cpu_up(cpu);
			}
		} else {
			queue_delayed_work_on(0, intelliplug_wq,
				&intelli_plug_work,
				msecs_to_jiffies(sampling_time));
		}
	}
};


static ssize_t intelli_plug_perf_boost_store(struct kobject *kobj,
			struct kobj_attribute *attr, const char *buf,
			size_t count)
{

	int boost_req;

	sscanf(buf, "%du", &boost_req);

	switch(boost_req) {
		case 0:
			intelli_plug_perf_boost(0);
			return count;
		case 1:
			intelli_plug_perf_boost(1);
			return count;
		default:
			return -EINVAL;
	}
};

static struct kobj_attribute intelli_plug_perf_boost_attribute =
	__ATTR(perf_boost, 0220,
		NULL,
		intelli_plug_perf_boost_store);

static struct attribute *intelli_plug_perf_boost_attrs[] = {
	&intelli_plug_perf_boost_attribute.attr,
	NULL,
};

static struct attribute_group intelli_plug_perf_boost_attr_group = {
	.attrs = intelli_plug_perf_boost_attrs,
};

static struct kobject *intelli_plug_perf_boost_kobj;
