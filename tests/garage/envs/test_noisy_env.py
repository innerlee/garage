import pickle
import unittest

from garage.envs.box2d import CartpoleEnv
from garage.envs.noisy_env import DelayedActionEnv
from garage.envs.noisy_env import NoisyObservationEnv
from tests.helpers import step_env


class TestDelayedActionEnv(unittest.TestCase):
    def test_pickleable(self):
        inner_env = CartpoleEnv(frame_skip=10)
        env = DelayedActionEnv(inner_env, action_delay=10)
        round_trip = pickle.loads(pickle.dumps(env))
        assert round_trip
        assert round_trip.action_delay == env.action_delay
        assert round_trip.env.frame_skip == env.env.frame_skip
        step_env(round_trip)


class TestNoisyObservationEnv(unittest.TestCase):
    def test_pickleable(self):
        inner_env = CartpoleEnv(frame_skip=10)
        env = NoisyObservationEnv(inner_env, obs_noise=5.)
        round_trip = pickle.loads(pickle.dumps(env))
        assert round_trip
        assert round_trip.obs_noise == env.obs_noise
        assert round_trip.env.frame_skip == env.env.frame_skip
        step_env(round_trip)
